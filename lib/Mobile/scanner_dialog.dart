import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

final SupabaseClient supabase = Supabase.instance.client;

class ContinuousScannerDialog extends StatefulWidget {
  const ContinuousScannerDialog({super.key});

  @override
  State<ContinuousScannerDialog> createState() => _ContinuousScannerDialogState();
}

class _ContinuousScannerDialogState extends State<ContinuousScannerDialog> {
  bool _isProcessing = false;
  String? _lastScan;
  DateTime _lastScanTime = DateTime.now();

  Future<void> _showPopup(String message, {Color color = Colors.green}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
              )
            ],
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _prosesAbsensi(int siswaId, String namaSiswa) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now();

    // Cek apakah sudah ada absensi hari ini
    final existingList = await supabase
        .from('absensi')
        .select()
        .eq('siswa_id', siswaId)
        .eq('tanggal', today);

    if (existingList.isEmpty) {
      // Belum absen hari ini -> masukkan waktu_masuk
      await supabase.from('absensi').insert({
        'siswa_id': siswaId,
        'tanggal': today,
        'status': 'hadir',
        'waktu_masuk': now.toIso8601String().substring(11, 19),
      });

      await _showPopup('✅ Absensi masuk tercatat\n$namaSiswa');
    } else {
      // Sudah absen -> langsung isi waktu_pulang jika belum ada
      final existing = existingList.first;
      final waktuPulang = existing['waktu_pulang'];

      if (waktuPulang != null) {
        await _showPopup('⚠️ Sudah tercatat waktu pulang sebelumnya', color: Colors.orange);
        return;
      }

      // Update waktu_pulang tanpa cek delay
      await supabase
          .from('absensi')
          .update({'waktu_pulang': now.toIso8601String().substring(11, 19)})
          .eq('id', existing['id']);

      await _showPopup('🏁 Waktu pulang tercatat\n$namaSiswa');
    }
  }

  Future<void> _handleScan(String result) async {
    if (_isProcessing) return;

    final now = DateTime.now();
    if (result == _lastScan && now.difference(_lastScanTime).inMilliseconds < 1200) {
      return;
    }

    _lastScan = result;
    _lastScanTime = now;

    setState(() => _isProcessing = true);

    try {
      final Map<String, dynamic> qrData = jsonDecode(result);
      final int? siswaId = qrData['siswa_id'] as int?;
      final String? namaSiswa = qrData['nama'] as String?;
      final String? tipeData = qrData['tipe_data'] as String?;

      if (tipeData != 'ABSENSI' || siswaId == null || namaSiswa == null) {
        throw Exception('QR tidak valid atau data tidak lengkap');
      }

      await _prosesAbsensi(siswaId, namaSiswa);
    } catch (e) {
      String msg = '❌ Gagal absensi';
      if (e is PostgrestException && e.code == '23505') {
        msg = '⚠️ Siswa sudah absen hari ini';
      } else if (e is FormatException) {
        msg = '❌ Format QR tidak valid';
      }

      await _showPopup(msg, color: Colors.red);
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.8;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kamera fullscreen
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              torchEnabled: false,
              returnImage: false,
            ),
            onDetect: (capture) {
              final barcode = capture.barcodes.first.rawValue;
              if (barcode != null) _handleScan(barcode);
            },
          ),

          // Overlay luar border
          LayoutBuilder(
            builder: (context, constraints) {
              final top = (constraints.maxHeight - scanBoxSize) / 2;
              final left = (constraints.maxWidth - scanBoxSize) / 2;
              return Stack(
                children: [
                  Positioned(top: 0, left: 0, right: 0, height: top, child: Container(color: Colors.black.withOpacity(0.5))),
                  Positioned(bottom: 0, left: 0, right: 0, height: top, child: Container(color: Colors.black.withOpacity(0.5))),
                  Positioned(top: top, bottom: top, left: 0, width: left, child: Container(color: Colors.black.withOpacity(0.5))),
                  Positioned(top: top, bottom: top, right: 0, width: left, child: Container(color: Colors.black.withOpacity(0.5))),
                ],
              );
            },
          ),

          // Kotak area scan
          Center(
            child: Container(
              width: scanBoxSize,
              height: scanBoxSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 4),
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
              ),
            ),
          ),

          // Tombol close
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Petunjuk teks
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              '📷 Arahkan QR ke dalam kotak\nScanner aktif terus.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Overlay processing
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.green),
            ),
        ],
      ),
    );
  }
}
