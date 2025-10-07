import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_absensi_mts/Mobile/formLogin.dart';
import 'package:app_absensi_mts/Mobile/dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      // ✅ gunakan stream yang benar
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Loading awal
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Ambil session dari snapshot.data?.session
        final session = snapshot.data?.session;

        // ✅ Jika user sudah login
        if (session != null) {
          return const DashboardScreen();
        }

        // ❌ Kalau tidak login, arahkan ke halaman login
        return const LoginScreen();
      },
    );
  }
}
