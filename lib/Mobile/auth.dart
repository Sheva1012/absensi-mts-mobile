import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import semua halaman tujuan
import 'formLogin.dart';
import 'dashboard.dart';
import 'absensi.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Tunggu frame pertama selesai dirender untuk menghindari error build
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      print("[AuthWrapper] Tidak ada sesi aktif, mengarahkan ke LoginScreen.");
      // Jika tidak ada sesi, arahkan ke halaman login
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false);
      return;
    }

    // Jika ada sesi, ambil peran pengguna
    print("[AuthWrapper] Sesi ditemukan untuk user ID: ${session.user.id}. Mengambil peran...");
    try {
      final userId = session.user.id;
      final data = await Supabase.instance.client
          .from('guru') // <-- PASTIKAN NAMA TABEL INI BENAR ('guru' atau 'profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = data['role'] as String?;
      print("[AuthWrapper] Peran ditemukan: '$role'. Mengarahkan pengguna...");

      if (!mounted) return;

      // Arahkan berdasarkan peran
      if (role == 'guru') {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false);
      } else if (role == 'admin') {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const ScanDashboardScreen()),
            (route) => false);
      } else {
        // Jika peran tidak dikenali, logout dan kembali ke login
        print("[AuthWrapper] Peran tidak dikenali. Melakukan logout...");
        await Supabase.instance.client.auth.signOut();
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false);
      }
    } catch (e) {
      // Jika gagal mengambil profil (misalnya, data tidak ada atau RLS salah)
      print("!!! ERROR di AuthWrapper: Gagal mengambil profil. Pesan: ${e.toString()}");
      print("[AuthWrapper] Melakukan logout karena gagal mengambil profil...");
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan layar loading saat proses redirect berjalan
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

