import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KelasLogic extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // State Data
  List<Map<String, dynamic>> _originalList = [];
  List<Map<String, dynamic>> filteredList = [];

  bool isLoading = true;
  String errorMessage = '';

  // State Search
  final TextEditingController searchController = TextEditingController();

  // Timer
  Timer? _autoRefreshTimer;

  // Nama kelas yang sedang dibuka
  String currentClassName = '';

  void init(String namaKelas) {
    currentClassName = namaKelas;
    fetchData(); // Fetch awal
    _startAutoRefresh(); // Mulai timer

    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh setiap 10 detik (jangan terlalu cepat agar tidak spam server)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchData(isBackground: true);
    });
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      filteredList = List.from(_originalList);
    } else {
      filteredList = _originalList.where((s) {
        final nama = (s['nama'] ?? '').toString().toLowerCase();
        return nama.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> fetchData({bool isBackground = false}) async {
    if (!isBackground) {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
    }

    try {
      // Panggil RPC yang baru dibuat
      final response = await _supabase.rpc(
        'get_siswa_kelas_hari_ini',
        params: {'p_nama_kelas': currentClassName},
      );

      final dataList = List<Map<String, dynamic>>.from(response);

      _originalList = dataList;

      // Terapkan ulang filter pencarian agar hasil search tidak hilang saat refresh
      _onSearchChanged();
    } catch (e) {
      if (!isBackground) {
        errorMessage = 'Gagal memuat data: $e';
      }
      debugPrint("Error KelasLogic: $e");
    } finally {
      if (!isBackground) {
        isLoading = false;
        notifyListeners();
      } else {
        // Jika background refresh, tetap notify agar UI update status absensi terbaru
        notifyListeners();
      }
    }
  }

  // Helper untuk format status tampilan
  String getStatusDisplay(Map<String, dynamic> item) {
    final status = item['status_absensi'];
    if (status == null) return 'Belum Absen';
    return status.toString().toUpperCase();
  }

  Color getStatusColor(Map<String, dynamic> item) {
    final status = (item['status_absensi'] ?? '').toString().toLowerCase();
    switch (status) {
      case 'hadir':
        return Colors.green;
      case 'terlambat':
        return Colors.orange;
      case 'sakit':
        return Colors.blue;
      case 'izin':
        return Colors.purple;
      case 'alfa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
