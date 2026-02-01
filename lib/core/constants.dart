import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide constants and configuration
class AppConstants {
  static const String schoolName = 'MTs Sunan Gunung Jati';
  static const String appName = 'Aplikasi Absensi MTS';

  /// Get Supabase URL from environment variables
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'SUPABASE_URL is not configured. Please check your .env file.',
      );
    }
    return url;
  }

  /// Get Supabase Anonymous Key from environment variables
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is not configured. Please check your .env file.',
      );
    }
    return key;
  }

  /// Get application environment (development, staging, production)
  static String get appEnvironment {
    return dotenv.env['APP_ENVIRONMENT'] ?? 'development';
  }

  /// Check if running in production environment
  static bool get isProduction => appEnvironment == 'production';

  /// Check if running in development environment
  static bool get isDevelopment => appEnvironment == 'development';
}

// ============================================================================
// DATABASE TABLE NAMES
// ============================================================================

abstract class DbTables {
  static const String siswa = 'siswa';
  static const String guru = 'guru';
  static const String kelas = 'kelas';
  static const String absensi = 'absensi';
  static const String surat = 'surat';
}

// ============================================================================
// DATABASE COLUMN NAMES
// ============================================================================

abstract class SiswaColumns {
  static const String id = 'id';
  static const String nis = 'nis';
  static const String nama = 'nama';
  static const String status = 'status';
  static const String kelasId = 'kelas_id';
  static const String email = 'email';
  static const String noHp = 'no_hp';
  static const String alamat = 'alamat';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

abstract class GuruColumns {
  static const String id = 'id';
  static const String nip = 'nip';
  static const String nama = 'nama';
  static const String email = 'email';
  static const String noHp = 'no_hp';
  static const String status = 'status';
  static const String role = 'role';
  static const String fotoUrl = 'foto_url';
  static const String avatarUrl = 'avatar_url';
  static const String kelasDiampu = 'kelas_diampu';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

abstract class KelasColumns {
  static const String id = 'id';
  static const String namaKelas = 'nama_kelas';
  static const String tingkat = 'tingkat';
  static const String waliKelasId = 'wali_kelas_id';
  static const String jumlahSiswa = 'jumlah_siswa';
  static const String jamMasuk = 'jam_masuk';
  static const String jamPulang = 'jam_pulang';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

abstract class AbsensiColumns {
  static const String id = 'id';
  static const String siswaId = 'siswa_id';
  static const String tanggal = 'tanggal';
  static const String status = 'status';
  static const String keterangan = 'keterangan';
  static const String waktuMasuk = 'waktu_masuk';
  static const String waktuPulang = 'waktu_pulang';
  static const String suratUrl = 'surat_url';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

abstract class SuratColumns {
  static const String id = 'id';
  static const String siswaId = 'siswa_id';
  static const String tipe = 'tipe';
  static const String tanggal = 'tanggal';
  static const String alasan = 'alasan';
  static const String keterangan = 'keterangan';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

// ============================================================================
// ENUMS WITH DATABASE VALUE MAPPING
// ============================================================================

/// Student Status Enum
enum StudentStatus {
  aktif('aktif', 'Aktif'),
  lulus('lulus', 'Lulus'),
  tidakAktif('tidak aktif', 'Tidak Aktif');

  final String value;
  final String displayName;

  const StudentStatus(this.value, this.displayName);

  factory StudentStatus.fromValue(String value) {
    return StudentStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => StudentStatus.aktif,
    );
  }
}

/// Attendance Status Enum
enum AttendanceStatus {
  hadir('hadir', 'Hadir'),
  terlambat('terlambat', 'Terlambat'),
  sakit('sakit', 'Sakit'),
  izin('izin', 'Izin'),
  alfa('alfa', 'Alfa'),
  pulang('pulang', 'Pulang');

  final String value;
  final String displayName;

  const AttendanceStatus(this.value, this.displayName);

  factory AttendanceStatus.fromValue(String? value) {
    if (value == null || value.isEmpty) return AttendanceStatus.alfa;
    return AttendanceStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => AttendanceStatus.alfa,
    );
  }

  /// Check if status indicates student is present
  bool get isPresent =>
      this == AttendanceStatus.hadir || this == AttendanceStatus.pulang;

  /// Check if status indicates student is absent
  bool get isAbsent =>
      this == AttendanceStatus.sakit ||
      this == AttendanceStatus.izin ||
      this == AttendanceStatus.alfa;

  /// Check if status indicates student is late
  bool get isLate => this == AttendanceStatus.terlambat;

  /// Check if status requires a letter/document
  bool get requiresDocument =>
      this == AttendanceStatus.sakit || this == AttendanceStatus.izin;
}

/// User Role Enum
enum UserRole {
  guru('guru', 'Guru'),
  admin('admin', 'Admin');

  final String value;
  final String displayName;

  const UserRole(this.value, this.displayName);

  factory UserRole.fromValue(String? value) {
    if (value == null) return UserRole.guru;
    return UserRole.values.firstWhere(
      (role) => role.value == value.toLowerCase(),
      orElse: () => UserRole.guru,
    );
  }
}

/// Letter Type Enum
enum LetterType {
  izin('izin', 'Izin'),
  sakit('sakit', 'Sakit');

  final String value;
  final String displayName;

  const LetterType(this.value, this.displayName);

  factory LetterType.fromValue(String value) {
    return LetterType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => LetterType.izin,
    );
  }
}

// ============================================================================
// STATUS COLORS
// ============================================================================

abstract class StatusColors {
  static const Map<String, Color> attendanceColors = {
    'hadir': Color(0xFF4CAF50), // Green
    'terlambat': Color(0xFFFFC107), // Amber
    'sakit': Color(0xFF2196F3), // Blue
    'izin': Color(0xFF9C27B0), // Purple
    'alfa': Color(0xFFF44336), // Red
    'pulang': Color(0xFF00BCD4), // Cyan
  };

  static const Map<String, Color> studentStatusColors = {
    'aktif': Color(0xFF4CAF50), // Green
    'lulus': Color(0xFF2196F3), // Blue
    'tidak aktif': Color(0xFFFF5722), // Deep Orange
  };

  /// Get color for attendance status
  static Color getAttendanceColor(String? status) {
    if (status == null) return Colors.grey;
    return attendanceColors[status.toLowerCase()] ?? Colors.grey;
  }

  /// Get color for student status
  static Color getStudentStatusColor(String? status) {
    if (status == null) return Colors.grey;
    return studentStatusColors[status.toLowerCase()] ?? Colors.grey;
  }
}

// ============================================================================
// UI CONSTANTS
// ============================================================================

abstract class UiConstants {
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const int searchDebounceMs = 500;
  static const int autoRefreshSeconds = 10;
  static const int scanDebounceMs = 2000;

  // Brand Colors
  static const Color primaryColor = Color(0xFF2F6CB0);
  static const Color primaryColorLight = Color(0xFF5A9BD4);
  static const Color primaryColorDark = Color(0xFF1E4A7A);
}

// ============================================================================
// STORAGE BUCKETS
// ============================================================================

abstract class StorageBuckets {
  static const String suratKeterangan = 'surat_keterangan';
}

// ============================================================================
// RPC FUNCTION NAMES
// ============================================================================

abstract class RpcFunctions {
  static const String getGuruDashboardSummary = 'get_guru_dashboard_summary';
  static const String getSiswaKelasHariIni = 'get_siswa_kelas_hari_ini';
}
