import '../../core/constants.dart';

/// Model representing a teacher (Guru)
class Guru {
  final String id; // UUID from Supabase Auth
  final String nip;
  final String nama;
  final String? email;
  final String? noHp;
  final String status;
  final UserRole role;
  final String? fotoUrl;
  final String? avatarUrl;
  final Map<String, List<String>>? kelasDiampu;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Guru({
    required this.id,
    required this.nip,
    required this.nama,
    this.email,
    this.noHp,
    required this.status,
    required this.role,
    this.fotoUrl,
    this.avatarUrl,
    this.kelasDiampu,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Guru from JSON (typically from Supabase)
  factory Guru.fromJson(Map<String, dynamic> json) {
    // Parse kelas_diampu from JSON
    Map<String, List<String>>? parsedKelasDiampu;
    final rawKelas = json[GuruColumns.kelasDiampu];
    if (rawKelas is Map) {
      parsedKelasDiampu = rawKelas.map((key, value) {
        return MapEntry(key.toString(), List<String>.from(value as List));
      });
    }

    return Guru(
      id: json[GuruColumns.id] as String,
      nip: json[GuruColumns.nip] as String? ?? '',
      nama: json[GuruColumns.nama] as String? ?? '',
      email: json[GuruColumns.email] as String?,
      noHp: json[GuruColumns.noHp] as String?,
      status: json[GuruColumns.status] as String? ?? 'aktif',
      role: UserRole.fromValue(json[GuruColumns.role] as String?),
      fotoUrl: json[GuruColumns.fotoUrl] as String?,
      avatarUrl: json[GuruColumns.avatarUrl] as String?,
      kelasDiampu: parsedKelasDiampu,
      createdAt: json[GuruColumns.createdAt] != null
          ? DateTime.parse(json[GuruColumns.createdAt] as String)
          : DateTime.now(),
      updatedAt: json[GuruColumns.updatedAt] != null
          ? DateTime.parse(json[GuruColumns.updatedAt] as String)
          : null,
    );
  }

  /// Convert Guru to JSON for sending to Supabase
  Map<String, dynamic> toJson() => {
        GuruColumns.id: id,
        GuruColumns.nip: nip,
        GuruColumns.nama: nama,
        GuruColumns.email: email,
        GuruColumns.noHp: noHp,
        GuruColumns.status: status,
        GuruColumns.role: role.value,
        GuruColumns.fotoUrl: fotoUrl,
        GuruColumns.avatarUrl: avatarUrl,
        GuruColumns.kelasDiampu: kelasDiampu,
        GuruColumns.createdAt: createdAt.toIso8601String(),
        GuruColumns.updatedAt: updatedAt?.toIso8601String(),
      };

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is teacher
  bool get isGuru => role == UserRole.guru;

  /// Get display avatar URL (with fallback)
  String? get displayAvatarUrl => avatarUrl ?? fotoUrl;

  /// Get list of all class names taught
  List<String> get allClassNames {
    if (kelasDiampu == null) return [];
    return kelasDiampu!.values.expand((list) => list).toList();
  }

  /// Create a copy of this Guru with some fields replaced
  Guru copyWith({
    String? id,
    String? nip,
    String? nama,
    String? email,
    String? noHp,
    String? status,
    UserRole? role,
    String? fotoUrl,
    String? avatarUrl,
    Map<String, List<String>>? kelasDiampu,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guru(
      id: id ?? this.id,
      nip: nip ?? this.nip,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
      status: status ?? this.status,
      role: role ?? this.role,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      kelasDiampu: kelasDiampu ?? this.kelasDiampu,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Guru(id: $id, nip: $nip, nama: $nama, role: ${role.value})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Guru && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
