import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'scanner.dart'; // Pastikan ini mengarah ke file Scanner Widget Anda

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

  // Cache Jam Kelas untuk mengurangi query berulang
  final Map<int, Map<String, String>> _kelasJamCache = {};

  void _showToast(String message, {Color color = Colors.green}) {
    // Cancel toast sebelumnya agar tidak menumpuk
    Fluttertoast.cancel();

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _prosesAbsensi(
    int siswaId,
    String namaSiswa,
    int? kelasId,
  ) async {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final jamScanStr = DateFormat('HH:mm:ss').format(today);

    // Default Jam
    String jamMasukKelasStr = "07:00:00";
    String jamPulangKelasStr = "14:00:00";

    // 1. Ambil Jam Kelas (Cek Cache dulu)
    if (kelasId != null) {
      if (_kelasJamCache.containsKey(kelasId)) {
        jamMasukKelasStr = _kelasJamCache[kelasId]!['masuk']!;
        jamPulangKelasStr = _kelasJamCache[kelasId]!['pulang']!;
      } else {
        try {
          final kelasRes = await supabase
              .from('kelas')
              .select('jam_masuk, jam_pulang')
              .eq('id', kelasId)
              .maybeSingle();

          if (kelasRes != null) {
            jamMasukKelasStr = (kelasRes['jam_masuk'] as String?) ?? "07:00:00";
            jamPulangKelasStr =
                (kelasRes['jam_pulang'] as String?) ?? "14:00:00";

            // Simpan ke cache
            _kelasJamCache[kelasId] = {
              'masuk': jamMasukKelasStr,
              'pulang': jamPulangKelasStr,
            };
          }
        } catch (e) {
          debugPrint("Error jam kelas: $e");
        }
      }
    }

    // 2. Cek Data Absensi Hari Ini
    final existingData = await supabase
        .from('absensi')
        .select()
        .eq('siswa_id', siswaId)
        .eq('tanggal', todayStr)
        .maybeSingle(); // Lebih efisien daripada list.first

    // LOGIKA UTAMA
    // Dianggap 'Belum Masuk' jika data tidak ada, atau kolom waktu_masuk NULL
    final bool isBelumAbsenMasuk =
        existingData == null || existingData['waktu_masuk'] == null;

    if (isBelumAbsenMasuk) {
      // === SCAN MASUK ===

      // Parse Jam Batas
      final batasWaktuMasuk = DateTime.parse("$todayStr $jamMasukKelasStr");

      // Tentukan Status (Hadir / Terlambat)
      // Gunakan 'today' (waktu scan) dibandingkan dengan batas waktu
      String statusAbsen = today.isAfter(batasWaktuMasuk)
          ? 'terlambat'
          : 'hadir';

      if (existingData != null) {
        // Kasus: Data sudah ada (misal dari Cron Job Alfa) -> Update
        await supabase
            .from('absensi')
            .update({
              'status': statusAbsen,
              'waktu_masuk': jamScanStr,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingData['id']);
      } else {
        // Kasus: Data baru -> Insert
        await supabase.from('absensi').insert({
          'siswa_id': siswaId,
          'tanggal': todayStr,
          'status': statusAbsen,
          'waktu_masuk': jamScanStr,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) setState(() => _borderColor = Colors.green);

      if (statusAbsen == 'terlambat') {
        // Hitung keterlambatan (opsional, untuk info)
        final diff = today.difference(batasWaktuMasuk).inMinutes;
        _showToast('⚠️ TERLAMBAT $diff mnt\n$namaSiswa', color: Colors.orange);
      } else {
        _showToast('✅ MASUK BERHASIL\n$namaSiswa', color: Colors.green);
      }
    } else {
      // === SCAN PULANG ===

      // Validasi 1: Cek apakah sudah absen pulang sebelumnya
      if (existingData['waktu_pulang'] != null) {
        if (mounted) setState(() => _borderColor = Colors.orange);
        _showToast(
          '⚠️ Sudah absen pulang sebelumnya\n$namaSiswa',
          color: Colors.orange,
        );
        return;
      }

      // Validasi 2: Delay minimal 1 menit dari waktu masuk (mencegah double scan tak sengaja)
      final waktuMasukDb = existingData['waktu_masuk'] as String;
      final dtWaktuMasuk = DateTime.parse("$todayStr $waktuMasukDb");

      if (today.difference(dtWaktuMasuk).inSeconds < 60) {
        if (mounted) setState(() => _borderColor = Colors.orange);
        _showToast(
          '⏳ Tunggu sebentar sebelum absen pulang',
          color: Colors.orange,
        );
        return;
      }

      // Validasi 3: Cek Jam Pulang Resmi
      final batasWaktuPulang = DateTime.parse("$todayStr $jamPulangKelasStr");

      // Jika scan SEBELUM jam pulang, tolak (atau peringatkan)
      if (today.isBefore(batasWaktuPulang)) {
        if (mounted) setState(() => _borderColor = Colors.red);
        _showToast(
          '⛔ Belum jam pulang (${jamPulangKelasStr.substring(0, 5)})\n$namaSiswa',
          color: Colors.red,
        );
        return;
      }

      // Update Pulang
      await supabase
          .from('absensi')
          .update({
            'waktu_pulang': jamScanStr,
            'status': 'pulang', // Ubah status jadi pulang
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingData['id']);

      if (mounted) setState(() => _borderColor = Colors.blue);
      _showToast('👋 PULANG BERHASIL\n$namaSiswa', color: Colors.blue);
    }
  }

  Future<void> _handleScan(String result) async {
    if (_isProcessing) return;

    final now = DateTime.now();
    // Debounce: Cegah scan code yang SAMA dalam waktu 2 detik
    if (result == _lastScan &&
        now.difference(_lastScanTime).inMilliseconds < 2000) {
      return;
    }

    _lastScan = result;
    _lastScanTime = now;

    setState(() {
      _isProcessing = true;
      _borderColor = Colors.yellow; // Warna loading
    });

    try {
      // Cari Siswa berdasarkan NIS
      final siswaRes = await supabase
          .from('siswa')
          .select('id, nama, kelas_id')
          .eq('nis', result)
          .maybeSingle(); // Aman jika tidak ketemu

      if (siswaRes == null) {
        throw "Siswa tidak ditemukan";
      }

      final siswaId = siswaRes['id'] as int;
      final namaSiswa = siswaRes['nama'] as String;
      final kelasId = siswaRes['kelas_id'] as int?;

      await _prosesAbsensi(siswaId, namaSiswa, kelasId);
    } catch (e) {
      String msg = '❌ Gagal scan';
      if (e.toString().contains("Siswa tidak ditemukan")) {
        msg = '❌ NIS Tidak Terdaftar: $result';
      } else {
        msg = '❌ Error: $e';
      }

      if (mounted) setState(() => _borderColor = Colors.red);
      _showToast(msg, color: Colors.red);
    } finally {
      // Delay sejenak agar user lihat warna border status sebelum reset
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _borderColor =
              Colors.red; // Kembali ke standby (Merah = Kamera Nyala)
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan widget Scanner Anda menerima parameter borderColor
    return BarcodeScannerPage(onResult: _handleScan, borderColor: _borderColor);
  }
}
