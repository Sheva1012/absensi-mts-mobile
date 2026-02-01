import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Logic class for Class (Kelas) screen using ChangeNotifier
class KelasLogic extends ChangeNotifier {
  final SiswaRepository _siswaRepository = SiswaRepository();

  // State Data
  List<SiswaWithAbsensi> _originalList = [];
  List<SiswaWithAbsensi> filteredList = [];

  bool isLoading = true;
  String errorMessage = '';

  // Search State
  final TextEditingController searchController = TextEditingController();

  // Timer for auto-refresh
  Timer? _autoRefreshTimer;

  // Current class name
  String currentClassName = '';

  void init(String namaKelas) {
    currentClassName = namaKelas;
    fetchData();
    _startAutoRefresh();
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
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: UiConstants.autoRefreshSeconds),
      (_) => fetchData(isBackground: true),
    );
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      filteredList = List.from(_originalList);
    } else {
      filteredList = _originalList.where((s) {
        return s.nama.toLowerCase().contains(query);
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
      final dataList =
          await _siswaRepository.getStudentsByClassToday(currentClassName);

      // Sort by name alphabetically
      dataList.sort((a, b) => a.nama.compareTo(b.nama));

      // Assign sequential number
      for (int i = 0; i < dataList.length; i++) {
        dataList[i] = dataList[i].copyWith(no: i + 1);
      }

      _originalList = dataList;
      _onSearchChanged(); // Re-apply search filter
    } catch (e) {
      if (!isBackground) {
        errorMessage = 'Gagal memuat data: $e';
      }
      debugPrint('Error KelasLogic: $e');
    } finally {
      if (!isBackground) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Get status display text
  String getStatusDisplay(SiswaWithAbsensi item) {
    if (item.statusAbsensi == null) return 'Belum Absen';
    return item.statusAbsensi!.toUpperCase();
  }

  /// Get status color
  Color getStatusColor(SiswaWithAbsensi item) {
    return StatusColors.getAttendanceColor(item.statusAbsensi);
  }
}
