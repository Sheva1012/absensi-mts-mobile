import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import halaman-halaman yang benar
import 'formLogin.dart';
import 'scanner.dart';

final SupabaseClient supabase = Supabase.instance.client;

class ScanDashboardScreen extends StatefulWidget {
  const ScanDashboardScreen({super.key});

  @override
  State<ScanDashboardScreen> createState() => _ScanDashboardScreenState();
}

class _ScanDashboardScreenState extends State<ScanDashboardScreen> {
  /// Logout user dan kembali ke login
  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Membuka halaman scanner fullscreen dan menunggu hasilnya
  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          // Kirim fungsi callback yang akan dijalankan setelah scan berhasil
          onResult: (scannedValue) {
            // Kembali ke halaman ini dulu
            Navigator.pop(context); 
            // Kemudian proses hasilnya
            _handleScanResult(scannedValue);
          },
        ),
      ),
    );
  }

  /// Memproses hasil yang didapat dari scanner
  Future<void> _handleScanResult(String result) async {
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
      String msg = 'Gagal memproses absensi';
      if (e is FormatException) {
        msg = 'Format QR tidak valid';
      } else {
        msg = e.toString().replaceFirst("Exception: ", "");
      }
      _showPopup(msg, color: Colors.red);
    }
  }

  /// Logika untuk menyimpan data absensi ke Supabase
  Future<void> _prosesAbsensi(int siswaId, String namaSiswa) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now();

    final existingList = await supabase
        .from('absensi')
        .select()
        .eq('siswa_id', siswaId)
        .eq('tanggal', today);

    if (existingList.isEmpty) {
      // Belum ada absensi masuk -> insert baru
      await supabase.from('absensi').insert({
        'siswa_id': siswaId,
        'tanggal': today,
        'status': 'hadir', // Pastikan kolom 'status' diisi
        'waktu_masuk': now.toIso8601String().substring(11, 19),
      });
      _showPopup('✅ Absensi masuk tercatat\n$namaSiswa');
    } else {
      // Sudah ada absensi masuk -> update waktu pulang
      final existing = existingList.first;
      if (existing['waktu_pulang'] != null) {
        _showPopup('⚠️ Sudah tercatat waktu pulang sebelumnya', color: Colors.orange);
        return;
      }
      
      await supabase
          .from('absensi')
          .update({'waktu_pulang': now.toIso8601String().substring(11, 19)})
          .eq('id', existing['id']);
      _showPopup('🏁 Waktu pulang tercatat\n$namaSiswa');
    }
  }

  /// Menampilkan popup notifikasi
  Future<void> _showPopup(String message, {Color color = Colors.green}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Absensi'),
        backgroundColor: const Color(0xFF2F6CB0),
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'Mulai Scan Barcode',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _openScanner,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        spreadRadius: 4,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 80,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logoMts.png',
                    height: 70,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.school, size: 70, color: Colors.grey);
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "MTS Sunan Gunung Jati",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

