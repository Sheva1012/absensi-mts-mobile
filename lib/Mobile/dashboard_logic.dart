import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'formLogin.dart';

class DashboardLogic extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool isLoading = true;
  String errorMessage = '';

  // Data Profil Guru
  Map<String, dynamic>? guruProfile;
  Map<String, List<String>> kelasDiampu = {};

  // Data Dashboard
  List<Map<String, dynamic>> summaryList = [];
  double attendanceRate = 0.0;

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw "User tidak terautentikasi.";

      // 1. Ambil Profil Guru
      final guruRes = await _supabase
          .from('guru')
          .select()
          .eq('id', user.id)
          .single();

      guruProfile = guruRes;

      // Parse JSON kelas_diampu
      final rawKelas = guruRes['kelas_diampu'];
      if (rawKelas is Map) {
        kelasDiampu = rawKelas.map((key, value) {
          return MapEntry(key.toString(), List<String>.from(value));
        });
      }

      // 2. Ambil Summary via RPC (Jauh lebih cepat)
      final rpcRes = await _supabase.rpc(
        'get_guru_dashboard_summary',
        params: {'p_guru_id': user.id},
      );

      summaryList = List<Map<String, dynamic>>.from(rpcRes);

      // Hitung Global Rate
      int totalSiswa = 0;
      int totalHadir = 0;

      for (var s in summaryList) {
        totalSiswa += (s['total_siswa'] as int);
        totalHadir +=
            (s['hadir'] as int) +
            (s['terlambat'] as int); // Terlambat dihitung hadir
      }

      attendanceRate = totalSiswa == 0 ? 0 : (totalHadir / totalSiswa) * 100;
    } catch (e) {
      errorMessage = 'Gagal memuat data: $e';
      debugPrint("Dashboard Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    await _supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
