import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service for Supabase client access
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// Get Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Get current authenticated user
  User? get currentUser => client.auth.currentUser;

  /// Get current session
  Session? get currentSession => client.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;
}

/// Global instance for easy access
final supabaseService = SupabaseService();
