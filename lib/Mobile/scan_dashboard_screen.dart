import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'formLogin.dart';
import 'scanner_dialog.dart'; // Pastikan file ini ada

class ScanDashboardScreen extends StatefulWidget {
  const ScanDashboardScreen({super.key});

  @override
  State<ScanDashboardScreen> createState() => _ScanDashboardScreenState();
}

class _ScanDashboardScreenState extends State<ScanDashboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  // --- LOGOUT LOGIC ---
  Future<void> _handleLogout() async {
    // Tampilkan Dialog Konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- NAVIGASI SCANNER ---
  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true, // Animasi slide up (modal)
        builder: (context) => const ContinuousScannerDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan warna brand sekolah yang konsisten
    const primaryColor = Color(0xFF2F6CB0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Admin Absensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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

              // Judul Halaman
              const Text(
                'Mulai Scan Kehadiran',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap tombol di bawah untuk membuka kamera',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // --- TOMBOL SCANNER BESAR ---
              Material(
                color: Colors.white,
                elevation: 8,
                shadowColor: primaryColor.withOpacity(0.2),
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: _openScanner,
                  splashColor: primaryColor.withOpacity(0.1),
                  highlightColor: primaryColor.withOpacity(0.05),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 80,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "SCAN",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // --- FOOTER LOGO ---
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: Image.asset(
                      'assets/LogoMts.png', // Pastikan nama file konsisten
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.school,
                          size: 60,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "MTs Sunan Gunung Jati",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Versi 1.0.0",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
