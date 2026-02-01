import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

/// Repository for attendance (absensi) operations
class AbsensiRepository {
  final supabase.SupabaseClient _client = supabaseService.client;

  // Cache for class schedules to reduce database queries
  final Map<int, KelasSchedule> _scheduleCache = {};

  /// Get attendance for a student on a specific date
  Future<Absensi?> getAbsensiByDate({
    required int siswaId,
    required DateTime tanggal,
  }) async {
    try {
      final tanggalStr = DateFormat('yyyy-MM-dd').format(tanggal);
      final response = await _client
          .from(DbTables.absensi)
          .select()
          .eq(AbsensiColumns.siswaId, siswaId)
          .eq(AbsensiColumns.tanggal, tanggalStr)
          .maybeSingle();

      if (response == null) return null;
      return Absensi.fromJson(response);
    } on supabase.PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal mengambil data absensi: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Get class schedule with caching
  Future<KelasSchedule> getKelasSchedule(int kelasId) async {
    // Check cache first
    if (_scheduleCache.containsKey(kelasId)) {
      return _scheduleCache[kelasId]!;
    }

    try {
      final response = await _client
          .from(DbTables.kelas)
          .select('${KelasColumns.jamMasuk}, ${KelasColumns.jamPulang}')
          .eq(KelasColumns.id, kelasId)
          .maybeSingle();

      final schedule = KelasSchedule(
        kelasId: kelasId,
        jamMasuk: response?[KelasColumns.jamMasuk] as String? ??
            Kelas.defaultJamMasuk,
        jamPulang: response?[KelasColumns.jamPulang] as String? ??
            Kelas.defaultJamPulang,
      );

      // Cache the result
      _scheduleCache[kelasId] = schedule;
      return schedule;
    } on supabase.PostgrestException catch (e) {
      debugPrint('Error fetching schedule: ${e.message}');
      // Return default schedule on error
      return KelasSchedule(
        kelasId: kelasId,
        jamMasuk: Kelas.defaultJamMasuk,
        jamPulang: Kelas.defaultJamPulang,
      );
    }
  }

  /// Process check-in attendance from QR scan
  Future<AbsensiResult> processCheckIn({
    required int siswaId,
    required String namaSiswa,
    required int? kelasId,
  }) async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final jamScanStr = DateFormat('HH:mm:ss').format(now);

      // Get class schedule
      String jamMasukKelas = Kelas.defaultJamMasuk;
      if (kelasId != null) {
        final schedule = await getKelasSchedule(kelasId);
        jamMasukKelas = schedule.jamMasuk;
      }

      // Check existing attendance
      final existingData = await _client
          .from(DbTables.absensi)
          .select()
          .eq(AbsensiColumns.siswaId, siswaId)
          .eq(AbsensiColumns.tanggal, todayStr)
          .maybeSingle();

      final bool isBelumAbsenMasuk =
          existingData == null || existingData[AbsensiColumns.waktuMasuk] == null;

      if (isBelumAbsenMasuk) {
        // === CHECK-IN PROCESS ===
        final batasWaktuMasuk = DateTime.parse('$todayStr $jamMasukKelas');
        final isLate = now.isAfter(batasWaktuMasuk);
        final statusAbsen =
            isLate ? AttendanceStatus.terlambat : AttendanceStatus.hadir;

        int? lateMinutes;
        if (isLate) {
          lateMinutes = now.difference(batasWaktuMasuk).inMinutes;
        }

        if (existingData != null) {
          // Update existing record (e.g., from cron job alfa)
          await _client.from(DbTables.absensi).update({
            AbsensiColumns.status: statusAbsen.value,
            AbsensiColumns.waktuMasuk: jamScanStr,
            AbsensiColumns.updatedAt: DateTime.now().toIso8601String(),
          }).eq('id', existingData['id']);
        } else {
          // Insert new record
          await _client.from(DbTables.absensi).insert({
            AbsensiColumns.siswaId: siswaId,
            AbsensiColumns.tanggal: todayStr,
            AbsensiColumns.status: statusAbsen.value,
            AbsensiColumns.waktuMasuk: jamScanStr,
            AbsensiColumns.createdAt: DateTime.now().toIso8601String(),
          });
        }

        return AbsensiResult(
          success: true,
          message: isLate
              ? '⚠️ TERLAMBAT $lateMinutes mnt\n$namaSiswa'
              : '✅ MASUK BERHASIL\n$namaSiswa',
          status: statusAbsen,
          isCheckIn: true,
          lateMinutes: lateMinutes,
        );
      } else {
        // Already checked in, need to process check-out
        return _processCheckOut(
          existingData: existingData,
          siswaId: siswaId,
          namaSiswa: namaSiswa,
          kelasId: kelasId,
          now: now,
          todayStr: todayStr,
          jamScanStr: jamScanStr,
        );
      }
    } on supabase.PostgrestException catch (e) {
      throw AttendanceException(
        message: 'Gagal memproses absensi: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Process check-out attendance
  Future<AbsensiResult> _processCheckOut({
    required Map<String, dynamic> existingData,
    required int siswaId,
    required String namaSiswa,
    required int? kelasId,
    required DateTime now,
    required String todayStr,
    required String jamScanStr,
  }) async {
    // Check if already checked out
    if (existingData[AbsensiColumns.waktuPulang] != null) {
      return AbsensiResult(
        success: false,
        message: '⚠️ Sudah absen pulang sebelumnya\n$namaSiswa',
        isCheckIn: false,
      );
    }

    // Validate minimum time since check-in (prevent double scan)
    final waktuMasukDb = existingData[AbsensiColumns.waktuMasuk] as String;
    final dtWaktuMasuk = DateTime.parse('$todayStr $waktuMasukDb');
    if (now.difference(dtWaktuMasuk).inSeconds < 60) {
      return AbsensiResult(
        success: false,
        message: '⏳ Tunggu sebentar sebelum absen pulang',
        isCheckIn: false,
      );
    }

    // Get class schedule for check-out time validation
    String jamPulangKelas = Kelas.defaultJamPulang;
    if (kelasId != null) {
      final schedule = await getKelasSchedule(kelasId);
      jamPulangKelas = schedule.jamPulang;
    }

    final batasWaktuPulang = DateTime.parse('$todayStr $jamPulangKelas');
    if (now.isBefore(batasWaktuPulang)) {
      return AbsensiResult(
        success: false,
        message:
            '⛔ Belum jam pulang (${jamPulangKelas.substring(0, 5)})\n$namaSiswa',
        isCheckIn: false,
      );
    }

    // Update check-out
    await _client.from(DbTables.absensi).update({
      AbsensiColumns.waktuPulang: jamScanStr,
      AbsensiColumns.status: AttendanceStatus.pulang.value,
      AbsensiColumns.updatedAt: DateTime.now().toIso8601String(),
    }).eq('id', existingData['id']);

    return AbsensiResult(
      success: true,
      message: '👋 PULANG BERHASIL\n$namaSiswa',
      status: AttendanceStatus.pulang,
      isCheckIn: false,
    );
  }

  /// Update or insert attendance manually (for teacher validation)
  Future<bool> upsertAbsensi({
    required int siswaId,
    required DateTime tanggal,
    required AttendanceStatus status,
  }) async {
    try {
      final tanggalStr = tanggal.toIso8601String().split('T').first;

      final data = {
        AbsensiColumns.siswaId: siswaId,
        AbsensiColumns.tanggal: tanggalStr,
        AbsensiColumns.status: status.value,
        AbsensiColumns.updatedAt: DateTime.now().toIso8601String(),
      };

      await _client.from(DbTables.absensi).upsert(
            data,
            onConflict: '${AbsensiColumns.siswaId}, ${AbsensiColumns.tanggal}',
          );

      return true;
    } on supabase.PostgrestException catch (e) {
      debugPrint('Error upsert absensi: ${e.message}');
      return false;
    }
  }

  /// Upsert surat keterangan
  Future<String?> upsertSurat({
    required int siswaId,
    required DateTime tanggal,
    required AttendanceStatus status,
    required File file,
  }) async {
    try {
      // 1. Upload file
      final fileUrl = await uploadSuratKeterangan(
        siswaId: siswaId,
        tanggal: tanggal,
        file: file,
      );
      if (fileUrl == null) return null;

      // 2. Upsert to surat table
      final tanggalStr = tanggal.toIso8601String().split('T').first;
      final data = {
        'siswa_id': siswaId,
        'tanggal': tanggalStr,
        'jenis': status.value, // 'sakit' or 'izin'
        'file_url': fileUrl,
      };

      await _client.from('surat').upsert(
            data,
            onConflict: 'siswa_id, tanggal',
          );

      return fileUrl;
    } catch (e) {
      debugPrint('Error upserting surat: $e');
      return null;
    }
  }

  /// Delete surat keterangan if exists
  Future<void> deleteSurat({
    required int siswaId,
    required DateTime tanggal,
  }) async {
    try {
      final tanggalStr = tanggal.toIso8601String().split('T').first;
      await _client
          .from('surat')
          .delete()
          .eq('siswa_id', siswaId)
          .eq('tanggal', tanggalStr);
    } catch (e) {
      debugPrint('Error deleting surat: $e');
    }
  }

  /// Upload letter document to storage
  Future<String?> uploadSuratKeterangan({
    required int siswaId,
    required DateTime tanggal,
    required File file,
  }) async {
    try {
      final tanggalStr = tanggal.toIso8601String().split('T').first;
      final ext = file.path.split('.').last;
      final fileName = '${siswaId}_$tanggalStr.$ext';
      final filePath = 'absensi/$fileName';

      await _client.storage.from(StorageBuckets.suratKeterangan).upload(
            filePath,
            file,
            fileOptions: const supabase.FileOptions(upsert: true),
          );

      return _client.storage
          .from(StorageBuckets.suratKeterangan)
          .getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Error uploading surat: $e');
      return null;
    }
  }

  /// Clear schedule cache (useful after data update)
  void clearScheduleCache() {
    _scheduleCache.clear();
  }
}
