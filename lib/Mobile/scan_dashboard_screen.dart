import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import halaman-halaman yang benar
import 'formLogin.dart';
import 'scanner_dialog.dart'; 

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

  /// PERBAIKAN: Fungsi ini sekarang hanya membuka halaman scanner
  /// Logika pemrosesan scan ada di dalam ContinuousScannerDialog
  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            const ContinuousScannerDialog(), // <-- Memanggil scanner yang benar
      ),
    );
  }

  // PERBAIKAN: Logika di bawah ini ( _handleScanResult, _prosesAbsensi, _showPopup )
  // telah dihapus karena sudah ada di dalam file 'scanner_dialog.dart'.
  // Ini mencegah duplikasi dan memperbaiki alur navigasi.

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
                onTap:
                    _openScanner, // <-- Memanggil fungsi yang sudah diperbaiki
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
                      return const Icon(
                        Icons.school,
                        size: 70,
                        color: Colors.grey,
                      );
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
