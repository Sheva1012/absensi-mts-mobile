import '../../core/constants.dart';

/// Model representing attendance record (Absensi)
class Absensi {
  final int id;
  final int siswaId;
  final DateTime tanggal;
  final AttendanceStatus status;
  final String? keterangan;
  final String? waktuMasuk;
  final String? waktuPulang;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Absensi({
    required this.id,
    required this.siswaId,
    required this.tanggal,
    required this.status,
    this.keterangan,
    this.waktuMasuk,
    this.waktuPulang,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Absensi from JSON (typically from Supabase)
  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json[AbsensiColumns.id] as int,
      siswaId: json[AbsensiColumns.siswaId] as int,
      tanggal: json[AbsensiColumns.tanggal] != null
          ? DateTime.parse(json[AbsensiColumns.tanggal] as String)
          : DateTime.now(),
      status: AttendanceStatus.fromValue(
        json[AbsensiColumns.status] as String? ?? 'hadir',
      ),
      keterangan: json[AbsensiColumns.keterangan] as String?,
      waktuMasuk: json[AbsensiColumns.waktuMasuk] as String?,
      waktuPulang: json[AbsensiColumns.waktuPulang] as String?,
      createdAt: json[AbsensiColumns.createdAt] != null
          ? DateTime.parse(json[AbsensiColumns.createdAt] as String)
          : DateTime.now(),
      updatedAt: json[AbsensiColumns.updatedAt] != null
          ? DateTime.parse(json[AbsensiColumns.updatedAt] as String)
          : null,
    );
  }

  /// Convert Absensi to JSON for sending to Supabase
  Map<String, dynamic> toJson() => {
        AbsensiColumns.id: id,
        AbsensiColumns.siswaId: siswaId,
        AbsensiColumns.tanggal: tanggal.toIso8601String().split('T').first,
        AbsensiColumns.status: status.value,
        AbsensiColumns.keterangan: keterangan,
        AbsensiColumns.waktuMasuk: waktuMasuk,
        AbsensiColumns.waktuPulang: waktuPulang,
        AbsensiColumns.createdAt: createdAt.toIso8601String(),
        AbsensiColumns.updatedAt: updatedAt?.toIso8601String(),
      };

  /// Create insert data for new attendance (without id)
  Map<String, dynamic> toInsertJson() => {
        AbsensiColumns.siswaId: siswaId,
        AbsensiColumns.tanggal: tanggal.toIso8601String().split('T').first,
        AbsensiColumns.status: status.value,
        AbsensiColumns.keterangan: keterangan,
        AbsensiColumns.waktuMasuk: waktuMasuk,
        AbsensiColumns.waktuPulang: waktuPulang,
        AbsensiColumns.createdAt: DateTime.now().toIso8601String(),
      };

  /// Create a copy of this Absensi with some fields replaced
  Absensi copyWith({
    int? id,
    int? siswaId,
    DateTime? tanggal,
    AttendanceStatus? status,
    String? keterangan,
    String? waktuMasuk,
    String? waktuPulang,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Absensi(
      id: id ?? this.id,
      siswaId: siswaId ?? this.siswaId,
      tanggal: tanggal ?? this.tanggal,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      waktuMasuk: waktuMasuk ?? this.waktuMasuk,
      waktuPulang: waktuPulang ?? this.waktuPulang,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if student has checked in
  bool get hasCheckedIn => waktuMasuk != null;

  /// Check if student has checked out
  bool get hasCheckedOut => waktuPulang != null;

  @override
  String toString() =>
      'Absensi(id: $id, siswaId: $siswaId, status: ${status.value}, tanggal: $tanggal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Absensi &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          siswaId == other.siswaId &&
          tanggal.year == other.tanggal.year &&
          tanggal.month == other.tanggal.month &&
          tanggal.day == other.tanggal.day;

  @override
  int get hashCode => id.hashCode ^ siswaId.hashCode ^ tanggal.hashCode;
}

/// Result model for check-in/check-out operation
class AbsensiResult {
  final bool success;
  final String message;
  final AttendanceStatus? status;
  final bool isCheckIn;
  final int? lateMinutes;

  AbsensiResult({
    required this.success,
    required this.message,
    this.status,
    this.isCheckIn = true,
    this.lateMinutes,
  });

  bool get isLate => lateMinutes != null && lateMinutes! > 0;
}
