import 'json.dart';

/// Peran pengguna sesuai kolom `role` di backend.
enum UserRole {
  admin,
  customer;

  static UserRole fromApi(String? nilai) {
    return nilai?.toUpperCase() == 'ADMIN' ? UserRole.admin : UserRole.customer;
  }

  String get api => this == UserRole.admin ? 'ADMIN' : 'CUSTOMER';

  bool get isAdmin => this == UserRole.admin;

  String get label => this == UserRole.admin ? 'Admin' : 'Customer';
}

/// Akun dari endpoint `/api/auth/login`, `/api/auth/register`, `/api/auth/me`.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: Json.toInt(json['id']) ?? 0,
      name: Json.text(json['name'], fallback: 'Pengguna'),
      email: Json.text(json['email']),
      role: UserRole.fromApi(Json.toText(json['role'])),
      createdAt: Json.toDate(json['created_at']),
    );
  }

  /// Inisial untuk avatar teks, mis. "Budi Santoso" -> "BS".
  String get inisial {
    final bagian = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((kata) => kata.isNotEmpty)
        .toList();

    if (bagian.isEmpty) return '?';
    final pertama = bagian.first.substring(0, 1);
    if (bagian.length == 1) return pertama.toUpperCase();
    final terakhir = bagian.last.substring(0, 1);
    return '$pertama$terakhir'.toUpperCase();
  }
}
