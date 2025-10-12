import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import halaman login & scanner
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

  /// ✅ BUKAN showDialog lagi — pakai Navigator.push untuk fullscreen scanner
  void _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true, // agar tampil dari bawah dan fullscreen
        builder: (context) => const ContinuousScannerDialog(),
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

              // Tombol Scan
              GestureDetector(
                onTap: _openScanner, // ganti dari _showScannerDialog ke _openScanner
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
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

              const SizedBox(height: 40),
              const Spacer(),

              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
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
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
