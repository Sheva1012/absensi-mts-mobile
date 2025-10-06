import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:app_absensi_mts/Mobile/formLogin.dart'; // Pastikan nama file login screen Anda benar
import 'package:app_absensi_mts/Mobile/dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder akan "mendengarkan" setiap perubahan status otentikasi
    // (login, logout, dll)
    return StreamBuilder<User?>(
      stream: Supabase.instance.client.auth.onAuthStateChange.map((authState) => authState.session?.user),
      builder: (context, snapshot) {
        // 1. Saat sedang memeriksa status
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tampilkan loading indicator di tengah layar
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. Jika snapshot memiliki data (artinya ada user yang login)
        if (snapshot.hasData) {
          // Arahkan ke halaman Dashboard
          return const DashboardScreen();
        }

        // 3. Jika snapshot tidak memiliki data (tidak ada user yang login)
        // Arahkan ke halaman Login
        return const LoginScreen();
      },
    );
  }
}
