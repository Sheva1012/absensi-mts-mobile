import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// PERBAIKAN: Import halaman scanner dan login
import 'scanner.dart';
import 'formLogin.dart';

class ScanDashboardScreen extends StatefulWidget {
  const ScanDashboardScreen({super.key});

  @override
  State<ScanDashboardScreen> createState() => _ScanDashboardScreenState();
}

class _ScanDashboardScreenState extends State<ScanDashboardScreen> {
  bool _isScanning = false;

  /// Fungsi ini akan dipanggil saat tombol power ditekan.
  void _startScan() async {
    setState(() {
      _isScanning = true;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Membuka kamera untuk memindai...'),
          duration: Duration(seconds: 1),
        ),
      );

    // Navigasi ke halaman scanner dan tunggu hasilnya
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );

    // Hentikan status scanning setelah kembali dari halaman scanner
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }

    // Lakukan sesuatu dengan hasil scan
    if (result != null) {
      print("Hasil Scan dari Dashboard: $result");

      // Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Absensi berhasil untuk: $result'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print("Proses scan dibatalkan atau tidak ada hasil.");
    }
  }

  /// Fungsi baru untuk menangani logout
  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
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
        // PERBAIKAN: Tambahkan tombol logout di sini
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
                onTap: _isScanning ? null : _startScan,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: _isScanning
                          ? Colors.blue.shade200
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isScanning
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.black.withOpacity(0.08),
                        spreadRadius: _isScanning ? 8 : 4,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.power_settings_new,
                      size: 80,
                      color: _isScanning ? Colors.blue : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_isScanning)
                const Text(
                  'Membuka kamera...',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              const Spacer(),
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

