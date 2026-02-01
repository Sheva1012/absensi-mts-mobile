import '../../core/constants.dart';

/// Model representing a student (Siswa)
class Siswa {
  final int id;
  final String nis;
  final String nama;
  final StudentStatus status;
  final int? kelasId;
  final String? email;
  final String? noHp;
  final String? alamat;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Siswa({
    required this.id,
    required this.nis,
    required this.nama,
    required this.status,
    this.kelasId,
    this.email,
    this.noHp,
    this.alamat,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Siswa from JSON (typically from Supabase)
  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      id: json[SiswaColumns.id] as int,
      nis: json[SiswaColumns.nis] as String? ?? '',
      nama: json[SiswaColumns.nama] as String? ?? '',
      status: StudentStatus.fromValue(
        json[SiswaColumns.status] as String? ?? 'aktif',
      ),
      kelasId: json[SiswaColumns.kelasId] as int?,
      email: json[SiswaColumns.email] as String?,
      noHp: json[SiswaColumns.noHp] as String?,
      alamat: json[SiswaColumns.alamat] as String?,
      createdAt: json[SiswaColumns.createdAt] != null
          ? DateTime.parse(json[SiswaColumns.createdAt] as String)
          : DateTime.now(),
      updatedAt: json[SiswaColumns.updatedAt] != null
          ? DateTime.parse(json[SiswaColumns.updatedAt] as String)
          : null,
    );
  }

  /// Convert Siswa to JSON for sending to Supabase
  Map<String, dynamic> toJson() => {
        SiswaColumns.id: id,
        SiswaColumns.nis: nis,
        SiswaColumns.nama: nama,
        SiswaColumns.status: status.value,
        SiswaColumns.kelasId: kelasId,
        SiswaColumns.email: email,
        SiswaColumns.noHp: noHp,
        SiswaColumns.alamat: alamat,
        SiswaColumns.createdAt: createdAt.toIso8601String(),
        SiswaColumns.updatedAt: updatedAt?.toIso8601String(),
      };

  /// Create a copy of this Siswa with some fields replaced
  Siswa copyWith({
    int? id,
    String? nis,
    String? nama,
    StudentStatus? status,
    int? kelasId,
    String? email,
    String? noHp,
    String? alamat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Siswa(
      id: id ?? this.id,
      nis: nis ?? this.nis,
      nama: nama ?? this.nama,
      status: status ?? this.status,
      kelasId: kelasId ?? this.kelasId,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
      alamat: alamat ?? this.alamat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Siswa(id: $id, nis: $nis, nama: $nama, status: ${status.value})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Siswa && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model for student data from RPC with attendance info
class SiswaWithAbsensi {
  final int id;
  final int no;
  final String nama;
  final String? statusAbsensi;
  final String? jamMasuk;
  final String? jamPulang;
  final String? fileUrl;

  SiswaWithAbsensi({
    required this.id,
    required this.no,
    required this.nama,
    this.statusAbsensi,
    this.jamMasuk,
    this.jamPulang,
    this.fileUrl,
  });

  factory SiswaWithAbsensi.fromJson(Map<String, dynamic> json) {
    return SiswaWithAbsensi(
      id: json['id'] as int,
      no: json['no'] as int? ?? 0,
      nama: json['nama'] as String? ?? '',
      statusAbsensi: json['status_absensi'] as String?,
      jamMasuk: json['jam_masuk'] as String?,
      jamPulang: json['jam_pulang'] as String?,
      fileUrl: json['file_url'] as String?,
    );
  }

  /// Get attendance status as enum
  AttendanceStatus get attendanceStatus =>
      AttendanceStatus.fromValue(statusAbsensi);

  /// Check if student has checked in today
  bool get hasCheckedIn => jamMasuk != null;

  /// Check if student has checked out today
  bool get hasCheckedOut => jamPulang != null;

  SiswaWithAbsensi copyWith({
    int? id,
    int? no,
    String? nama,
    String? statusAbsensi,
    String? jamMasuk,
    String? jamPulang,
    String? fileUrl,
  }) {
    return SiswaWithAbsensi(
      id: id ?? this.id,
      no: no ?? this.no,
      nama: nama ?? this.nama,
      statusAbsensi: statusAbsensi ?? this.statusAbsensi,
      jamMasuk: jamMasuk ?? this.jamMasuk,
      jamPulang: jamPulang ?? this.jamPulang,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }

  @override
  String toString() =>
      'SiswaWithAbsensi(id: $id, nama: $nama, status: $statusAbsensi)';
}
