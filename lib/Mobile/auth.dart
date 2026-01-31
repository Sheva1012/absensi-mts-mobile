import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import halaman tujuan
import 'formLogin.dart';
import 'dashboard.dart'; // Dashboard Guru
import 'scan_dashboard_screen.dart'; // Dashboard Admin (Scanner)

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // DI DALAM FILE auth_wrapper.dart

  Future<void> _checkAuth() async {
    await Future.delayed(Duration.zero);
    
    print("--- [DEBUG] MULAI PENGECEKAN AUTH ---");

    // 1. Cek Koneksi Supabase
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      print("--- [DEBUG] Session Kosong. Mengarahkan ke Login. ---");
      if (!mounted) return;
      _navigateTo(const LoginScreen());
      return;
    }

    final userId = session.user.id;
    final email = session.user.email;
    print("--- [DEBUG] User Login Ditemukan ---");
    print("--- [DEBUG] Email: $email");
    print("--- [DEBUG] User UID: $userId");

    // 2. Coba Ambil Data Guru
    try {
      print("--- [DEBUG] Mencoba query ke tabel 'guru'... ---");

      // Menggunakan maybeSingle() agar tidak error crash jika data kosong
      final data = await supabase
          .from('guru')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      print("--- [DEBUG] Hasil Query Database: $data ---");

      if (data == null) {
        print("!!! [CRITICAL ERROR] Data tidak ditemukan di tabel guru !!!");
        print(
          "Penyebab: ID di tabel 'guru' TIDAK SAMA dengan User UID ($userId)",
        );

        if (mounted) {
          setState(() {
            _isError = true;
            _errorMessage =
                "Akun terdaftar di Auth, tapi data profil 'guru' belum dibuat.\n\nUser ID: $userId";
          });
        }
        return;
      }

      final role = data['role'] as String?;
      print("--- [DEBUG] Role ditemukan: $role ---");

      if (!mounted) return;

      if (role == 'guru') {
        print("--- [DEBUG] Redirect ke Dashboard Guru ---");
        _navigateTo(const DashboardScreen());
      } else if (role == 'admin') {
        print("--- [DEBUG] Redirect ke Scan Dashboard ---");
        _navigateTo(const ScanDashboardScreen());
      } else {
        print("--- [DEBUG] Role tidak dikenal: $role ---");
        await supabase.auth.signOut();
        _navigateTo(const LoginScreen());
      }
    } catch (e) {
      print("!!! [EXCEPTION] Error Keras: $e");
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = "Error Database: $e";
        });
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Sesuaikan warna brand sekolah
      body: Center(child: _isError ? _buildErrorView() : _buildLoadingView()),
    );
  }

  // Tampilan Loading dengan Logo (Splash Screen)
  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pastikan logo ada di assets
        Image.asset(
          'assets/LogoMts.png',
          width: 100,
          height: 100,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.school, size: 80, color: Colors.blue),
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text(
          "Memuat Data Pengguna...",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // Tampilan Error dengan Tombol Retry
  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _checkAuth, // Coba lagi
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
          ),
          TextButton(
            onPressed: () async {
              // Opsi logout manual jika user ingin ganti akun
              await Supabase.instance.client.auth.signOut();
              if (mounted) _navigateTo(const LoginScreen());
            },
            child: const Text("Logout / Ganti Akun"),
          ),
        ],
      ),
    );
  }
}
