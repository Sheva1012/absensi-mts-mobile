import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

/// Repository for student (siswa) operations
class SiswaRepository {
  final SupabaseClient _client = supabaseService.client;

  /// Find student by NIS (from QR code scan)
  Future<Siswa?> findByNis(String nis) async {
    try {
      final response = await _client
          .from(DbTables.siswa)
          .select()
          .eq(SiswaColumns.nis, nis)
          .maybeSingle();

      if (response == null) return null;
      return Siswa.fromJson(response);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal mencari siswa: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Get student by ID
  Future<Siswa?> getById(int id) async {
    try {
      final response = await _client
          .from(DbTables.siswa)
          .select()
          .eq(SiswaColumns.id, id)
          .maybeSingle();

      if (response == null) return null;
      return Siswa.fromJson(response);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal mengambil data siswa: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Get students by class name with today's attendance (via RPC)
  Future<List<SiswaWithAbsensi>> getStudentsByClassToday(
      String namaKelas) async {
    try {
      final response = await _client.rpc(
        RpcFunctions.getSiswaKelasHariIni,
        params: {'p_nama_kelas': namaKelas},
      );

      return (response as List)
          .map((item) =>
              SiswaWithAbsensi.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal mengambil data siswa kelas: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Get student for scan with minimal data needed
  Future<({int id, String nama, int? kelasId})?> findForScan(String nis) async {
    try {
      final response = await _client
          .from(DbTables.siswa)
          .select('${SiswaColumns.id}, ${SiswaColumns.nama}, ${SiswaColumns.kelasId}')
          .eq(SiswaColumns.nis, nis)
          .maybeSingle();

      if (response == null) return null;

      return (
        id: response[SiswaColumns.id] as int,
        nama: response[SiswaColumns.nama] as String,
        kelasId: response[SiswaColumns.kelasId] as int?,
      );
    } on PostgrestException catch (e) {
      debugPrint('Error finding student for scan: ${e.message}');
      return null;
    }
  }
}
