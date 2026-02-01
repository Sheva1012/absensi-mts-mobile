import '../../core/constants.dart';

/// Model representing a class (Kelas)
class Kelas {
  final int id;
  final String namaKelas;
  final String tingkat;
  final int? waliKelasId;
  final int? jumlahSiswa;
  final String? jamMasuk;
  final String? jamPulang;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Kelas({
    required this.id,
    required this.namaKelas,
    required this.tingkat,
    this.waliKelasId,
    this.jumlahSiswa,
    this.jamMasuk,
    this.jamPulang,
    required this.createdAt,
    this.updatedAt,
  });

  /// Default times for class schedule
  static const String defaultJamMasuk = '07:00:00';
  static const String defaultJamPulang = '14:00:00';

  /// Create Kelas from JSON (typically from Supabase)
  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      id: json[KelasColumns.id] as int,
      namaKelas: json[KelasColumns.namaKelas] as String? ?? '',
      tingkat: json[KelasColumns.tingkat] as String? ?? '',
      waliKelasId: json[KelasColumns.waliKelasId] as int?,
      jumlahSiswa: json[KelasColumns.jumlahSiswa] as int?,
      jamMasuk: json[KelasColumns.jamMasuk] as String?,
      jamPulang: json[KelasColumns.jamPulang] as String?,
      createdAt: json[KelasColumns.createdAt] != null
          ? DateTime.parse(json[KelasColumns.createdAt] as String)
          : DateTime.now(),
      updatedAt: json[KelasColumns.updatedAt] != null
          ? DateTime.parse(json[KelasColumns.updatedAt] as String)
          : null,
    );
  }

  /// Convert Kelas to JSON for sending to Supabase
  Map<String, dynamic> toJson() => {
        KelasColumns.id: id,
        KelasColumns.namaKelas: namaKelas,
        KelasColumns.tingkat: tingkat,
        KelasColumns.waliKelasId: waliKelasId,
        KelasColumns.jumlahSiswa: jumlahSiswa,
        KelasColumns.jamMasuk: jamMasuk,
        KelasColumns.jamPulang: jamPulang,
        KelasColumns.createdAt: createdAt.toIso8601String(),
        KelasColumns.updatedAt: updatedAt?.toIso8601String(),
      };

  /// Get effective check-in time (with default fallback)
  String get effectiveJamMasuk => jamMasuk ?? defaultJamMasuk;

  /// Get effective check-out time (with default fallback)
  String get effectiveJamPulang => jamPulang ?? defaultJamPulang;

  /// Create a copy of this Kelas with some fields replaced
  Kelas copyWith({
    int? id,
    String? namaKelas,
    String? tingkat,
    int? waliKelasId,
    int? jumlahSiswa,
    String? jamMasuk,
    String? jamPulang,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Kelas(
      id: id ?? this.id,
      namaKelas: namaKelas ?? this.namaKelas,
      tingkat: tingkat ?? this.tingkat,
      waliKelasId: waliKelasId ?? this.waliKelasId,
      jumlahSiswa: jumlahSiswa ?? this.jumlahSiswa,
      jamMasuk: jamMasuk ?? this.jamMasuk,
      jamPulang: jamPulang ?? this.jamPulang,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Kelas(id: $id, namaKelas: $namaKelas, tingkat: $tingkat)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kelas &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          namaKelas == other.namaKelas;

  @override
  int get hashCode => id.hashCode ^ namaKelas.hashCode;
}

/// Simple class schedule model for caching
class KelasSchedule {
  final int kelasId;
  final String jamMasuk;
  final String jamPulang;

  KelasSchedule({
    required this.kelasId,
    required this.jamMasuk,
    required this.jamPulang,
  });

  factory KelasSchedule.fromKelas(Kelas kelas) {
    return KelasSchedule(
      kelasId: kelas.id,
      jamMasuk: kelas.effectiveJamMasuk,
      jamPulang: kelas.effectiveJamPulang,
    );
  }
}
