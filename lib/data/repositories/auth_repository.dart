import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

/// Repository for teacher (guru) and authentication operations
class AuthRepository {
  final supabase.SupabaseClient _client = supabaseService.client;

  /// Sign in with email and password
  Future<supabase.AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(
        message: e.message,
        originalException: e,
      );
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supabase.AuthException catch (e) {
      debugPrint('Sign out error: ${e.message}');
    }
  }

  /// Get current user's guru profile
  Future<Guru?> getCurrentGuruProfile() async {
    final userId = supabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from(DbTables.guru)
          .select()
          .eq(GuruColumns.id, userId)
          .maybeSingle();

      if (response == null) return null;
      return Guru.fromJson(response);
    } on supabase.PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal mengambil profil guru: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Get user role for routing
  Future<UserRole?> getCurrentUserRole() async {
    final userId = supabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from(DbTables.guru)
          .select(GuruColumns.role)
          .eq(GuruColumns.id, userId)
          .maybeSingle();

      if (response == null) return null;
      return UserRole.fromValue(response[GuruColumns.role] as String?);
    } on supabase.PostgrestException catch (e) {
      debugPrint('Error getting user role: ${e.message}');
      return null;
    }
  }

  /// Get dashboard summary for teacher
  Future<List<ClassSummary>> getDashboardSummary() async {
    final userId = supabaseService.currentUserId;
    if (userId == null) {
      throw AuthException(message: 'User tidak terautentikasi');
    }

    try {
      final response = await _client.rpc(
        RpcFunctions.getGuruDashboardSummary,
        params: {'p_guru_id': userId},
      );

      return (response as List)
          .map((item) => ClassSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal mengambil data dashboard: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Check if current session is valid
  bool get hasValidSession => supabaseService.isAuthenticated;

  /// Get current user ID
  String? get currentUserId => supabaseService.currentUserId;
}
