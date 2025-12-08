class User {
  final String id; // UUID como String
  final String username;
  final String? nombre;
  final String? apellido;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.username,
    this.nombre,
    this.apellido,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Manejar created_at que puede venir como String o DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) {
        throw ArgumentError('DateTime value cannot be null');
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.parse(value);
      }
      throw ArgumentError('Cannot parse DateTime from ${value.runtimeType}');
    }

    return User(
      id: json['id'] as String, // UUID como String
      username: json['username'] as String,
      nombre: json['nombre'] as String?,
      apellido: json['apellido'] as String?,
      isActive: json['activo'] as bool? ?? true,
      createdAt: parseDateTime(json['created_at']),
      lastLoginAt: json['last_login_at'] != null
          ? parseDateTime(json['last_login_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nombre': nombre,
      'apellido': apellido,
      'activo': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }
}
