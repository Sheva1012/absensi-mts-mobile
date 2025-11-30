import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'scanner.dart';

final SupabaseClient supabase = Supabase.instance.client;

class ContinuousScannerDialog extends StatefulWidget {
  const ContinuousScannerDialog({super.key});

  @override
  State<ContinuousScannerDialog> createState() =>
      _ContinuousScannerDialogState();
}

class _ContinuousScannerDialogState extends State<ContinuousScannerDialog> {
  bool _isProcessing = false;
  String? _lastScan;
  DateTime _lastScanTime = DateTime.now();
  Color _borderColor = Colors.red;

  // --- 2. FUNGSI DIGANTI MENGGUNAKAN FLUTTERTOAST ---
  void _showToast(String message, {Color color = Colors.green}) {
    if (!mounted) return;

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT, // Durasi 1 detik
      gravity: ToastGravity.CENTER, // Posisi di tengah, seperti popup Anda
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 18.0, 
    );
  }
  // --- AKHIR PERUBAHAN FUNGSI ---

 Future<void> _prosesAbsensi(
    int siswaId,
    String namaSiswa,
    int? kelasId,
  ) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now();
    final String jamScanStr = now.toIso8601String().substring(11, 19);

    // Default jam
    const String defaultJamMasuk = "07:00:00";
    const String defaultJamPulang = "14:00:00";
    String jamMasukKelasStr = defaultJamMasuk;
    String jamPulangKelasStr = defaultJamPulang;

    if (kelasId != null) {
      try {
        final kelasRes = await supabase
            .from('kelas')
            .select('jam_masuk, jam_pulang')
            .eq('id', kelasId)
            .single();

        jamMasukKelasStr =
            (kelasRes['jam_masuk'] as String?) ?? defaultJamMasuk;
        jamPulangKelasStr =
            (kelasRes['jam_pulang'] as String?) ?? defaultJamPulang;
      } catch (e) {
        print("Error cari jam: $e. Menggunakan default.");
      }
    }

    // Ambil data absensi hari ini
    final existingList = await supabase
        .from('absensi')
        .select()
        .eq('siswa_id', siswaId)
        .eq('tanggal', today);

    // Variabel pembantu untuk mendeteksi status data
    final Map<String, dynamic>? existingData =
        existingList.isNotEmpty ? existingList.first : null;
    
    // LOGIKA UTAMA: Deteksi apakah ini Scan Masuk atau Pulang
    // Dianggap 'Belum Masuk' jika:
    // 1. Data belum ada sama sekali (Siswa baru), ATAU
    // 2. Data ada (dari Cron Job), tapi kolom 'waktu_masuk' masih NULL
    final bool isBelumAbsenMasuk = existingData == null || existingData['waktu_masuk'] == null;

    if (isBelumAbsenMasuk) {
      // === LOGIKA ABSENSI MASUK ===
      final tglHariIniStr = DateFormat('yyyy-MM-dd').format(now);
      final batasWaktuMasuk = DateTime.parse(
        "$tglHariIniStr $jamMasukKelasStr",
      );

      String statusAbsen = now.isAfter(batasWaktuMasuk) ? 'terlambat' : 'hadir';

      if (existingData != null) {
        // KASUS A: Data sudah ada (dari Cron Job 'Alfa') -> Lakukan UPDATE
        await supabase.from('absensi').update({
          'status': statusAbsen,
          'waktu_masuk': jamScanStr,
        }).eq('id', existingData['id']); // Update berdasarkan ID record yang sudah ada
      } else {
        // KASUS B: Data belum ada (Siswa baru insert setelah cron jalan) -> Lakukan INSERT
        await supabase.from('absensi').insert({
          'siswa_id': siswaId,
          'tanggal': today,
          'status': statusAbsen,
          'waktu_masuk': jamScanStr,
        });
      }

      if (mounted) setState(() => _borderColor = Colors.greenAccent);
      
      if (statusAbsen == 'terlambat') {
        _showToast(
          '⏱️ Anda TERLAMBAT ($jamScanStr)\n$namaSiswa',
          color: Colors.orange,
        );
      } else {
        _showToast('✅ Absensi masuk tercatat ($jamScanStr)\n$namaSiswa');
      }

    } else {
      // === LOGIKA ABSENSI PULANG ===
      // Masuk ke sini berarti 'waktu_masuk' SUDAH ADA isinya
      
      final waktuPulangTercatat = existingData['waktu_pulang']; // Aman pakai ! karena masuk else
      final waktuMasukStr = existingData['waktu_masuk'];

      if (waktuPulangTercatat != null) {
        _showToast(
          '⚠️ Sudah tercatat waktu pulang sebelumnya',
          color: Colors.orange,
        );
        return;
      }

      // Cek delay minimal 5 menit
      if (waktuMasukStr != null) {
        final waktuMasukToday = DateTime.parse("$today $waktuMasukStr");
        final durasi = now.difference(waktuMasukToday);

        if (durasi.inMinutes < 5) {
          _showToast(
            '⏱️ Belum bisa absen pulang.\nTunggu ${5 - durasi.inMinutes} menit lagi.',
            color: Colors.orange,
          );
          return;
        }
      }

      // Cek Jam Pulang Resmi
      final tglHariIniStr = DateFormat('yyyy-MM-dd').format(now);
      final batasWaktuPulang = DateTime.parse(
        "$tglHariIniStr $jamPulangKelasStr",
      );

      if (now.isBefore(batasWaktuPulang)) {
        if (mounted) setState(() => _borderColor = Colors.orange);
        _showToast(
          '🚫 Belum waktunya pulang. Jam pulang: ${jamPulangKelasStr.substring(0, 5)}',
          color: Colors.orange,
        );
        return;
      }

      // Update Pulang
      await supabase
          .from('absensi')
          .update({
            'waktu_pulang': jamScanStr,
            'status': 'pulang', // Opsional: Tergantung kebutuhan, apakah status mau diubah jadi 'pulang' atau tetap 'hadir'
          })
          .eq('id', existingData['id']);

      if (mounted) setState(() => _borderColor = Colors.greenAccent);
      _showToast('🏁 Absensi PULANG tercatat ($jamScanStr)\n$namaSiswa');
    }
  }

  Future<void> _handleScan(String result) async {
    if (_isProcessing) return;

    final now = DateTime.now();
    if (result == _lastScan &&
        now.difference(_lastScanTime).inMilliseconds < 1200) {
      return;
    }

    _lastScan = result;
    _lastScanTime = now;

    setState(() {
      _isProcessing = true;
      _borderColor = Colors.blueAccent;
    });

    try {
      final siswaRes = await supabase
          .from('siswa')
          .select('id, nama, kelas_id')
          .eq('nis', result)
          .single();

      final int? siswaId = siswaRes['id'] as int?;
      final String? namaSiswa = siswaRes['nama'] as String?;
      final int? kelasId = siswaRes['kelas_id'] as int?;

      if (siswaId == null || namaSiswa == null) {
        throw Exception('Data siswa tidak lengkap di database');
      }

      await _prosesAbsensi(siswaId, namaSiswa, kelasId);
    } catch (e) {
      String msg = '❌ Gagal absensi';
      if (e is PostgrestException) {
        if (e.code == 'PGRST116') {
          msg = '❌ QR tidak valid\nSiswa tidak ditemukan';
        } else if (e.code == '23505') {
          // Kasus ini mungkin tidak terjadi lagi karena ada pengecekan waktu pulang
          msg = '⚠️ Siswa sudah absen masuk hari ini';
        }
      } else if (e is FormatException) {
        msg = '❌ Format QR tidak valid';
      } else {
        msg = '❌ QR tidak dikenal';
        print(e.toString());
      }

      if (mounted) setState(() => _borderColor = Colors.red);
      // --- 3. DIUBAH: HAPUS AWAIT & GANTI NAMA FUNGSI ---
      _showToast(msg, color: Colors.red);
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _borderColor = Colors.red;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeScannerPage(onResult: _handleScan, borderColor: _borderColor);
  }
}
