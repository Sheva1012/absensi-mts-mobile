import 'package:flutter/material.dart';

import '../../core/exceptions.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Logic class for Dashboard using ChangeNotifier
class DashboardLogic extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  bool isLoading = true;
  String errorMessage = '';

  // Data Profil Guru
  Guru? guruProfile;
  Map<String, List<String>> kelasDiampu = {};

  // Data Dashboard
  List<ClassSummary> summaryList = [];
  double attendanceRate = 0.0;

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      // 1. Get Guru Profile
      guruProfile = await _authRepository.getCurrentGuruProfile();
      if (guruProfile == null) {
        throw AuthException(message: 'User tidak terautentikasi.');
      }

      // Parse kelas_diampu from profile
      if (guruProfile!.kelasDiampu != null) {
        kelasDiampu = guruProfile!.kelasDiampu!;
      }

      // 2. Get Dashboard Summary via RPC
      summaryList = await _authRepository.getDashboardSummary();

      // Calculate Global Attendance Rate
      int totalSiswa = 0;
      int totalHadir = 0;

      for (var summary in summaryList) {
        totalSiswa += summary.totalSiswa;
        totalHadir += summary.totalPresent; // hadir + terlambat
      }

      attendanceRate = totalSiswa == 0 ? 0 : (totalHadir / totalSiswa) * 100;
    } on AppException catch (e) {
      errorMessage = 'Gagal memuat data: ${e.message}';
      debugPrint('Dashboard Error: ${e.message}');
    } catch (e) {
      errorMessage = 'Gagal memuat data: $e';
      debugPrint('Dashboard Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
  }
}
