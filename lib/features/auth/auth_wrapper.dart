import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../../data/repositories/repositories.dart';
import 'form_login.dart';
import 'dashboard_screen.dart';
import '../scanner/scan_dashboard_screen.dart';

/// Widget that handles authentication state and routing
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthRepository _authRepository = AuthRepository();

  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(Duration.zero);

    debugPrint('--- [DEBUG] MULAI PENGECEKAN AUTH ---');

    // Check if user has valid session
    if (!_authRepository.hasValidSession) {
      debugPrint('--- [DEBUG] Session Kosong. Mengarahkan ke Login. ---');
      if (!mounted) return;
      _navigateTo(const LoginScreen());
      return;
    }

    final userId = _authRepository.currentUserId;
    debugPrint('--- [DEBUG] User UID: $userId');

    try {
      final role = await _authRepository.getCurrentUserRole();
      debugPrint('--- [DEBUG] Role ditemukan: ${role?.value} ---');

      if (role == null) {
        debugPrint('!!! [CRITICAL ERROR] Data tidak ditemukan di tabel guru !!!');
        if (mounted) {
          setState(() {
            _isError = true;
            _errorMessage =
                'Akun terdaftar di Auth, tapi data profil \'guru\' belum dibuat.\n\nUser ID: $userId';
          });
        }
        return;
      }

      if (!mounted) return;

      switch (role) {
        case UserRole.guru:
          debugPrint('--- [DEBUG] Redirect ke Dashboard Guru ---');
          _navigateTo(const DashboardScreen());
          break;
        case UserRole.admin:
          debugPrint('--- [DEBUG] Redirect ke Scan Dashboard ---');
          _navigateTo(const ScanDashboardScreen());
          break;
      }
    } on RepositoryException catch (e) {
      _handleError('Error Database: ${e.message}');
    } catch (e) {
      _handleError('Error tidak terduga: $e');
    }
  }

  void _handleError(String message) {
    debugPrint('!!! [EXCEPTION] $message');
    if (mounted) {
      setState(() {
        _isError = true;
        _errorMessage = message;
      });
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _handleLogout() async {
    await _authRepository.signOut();
    if (mounted) {
      _navigateTo(const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isError = false;
                            _errorMessage = '';
                          });
                          _checkAuth();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat...'),
          ],
        ),
      ),
    );
  }
}
