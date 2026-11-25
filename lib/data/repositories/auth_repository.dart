import '../../core/network/api_client.dart';
import '../models/json.dart';
import '../models/user.dart';

/// Hasil login/registrasi: akun dan token JWT-nya.
class AuthResult {
  const AuthResult({required this.user, required this.token});

  final User user;
  final String token;
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// POST /api/auth/login
  Future<AuthResult> login({required String email, required String password}) async {
    final data = await _api.post(
      '/api/auth/login',
      body: <String, dynamic>{'email': email.trim(), 'password': password},
    );
    return _keHasil(data);
  }

  /// POST /api/auth/register — role selalu CUSTOMER dari backend.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/api/auth/register',
      body: <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
    return _keHasil(data);
  }

  /// GET /api/auth/me
  Future<User> me() async {
    final data = Json.asMap(await _api.get('/api/auth/me'));
    return User.fromJson(Json.asMap(data['user']));
  }

  /// PATCH /api/auth/me
  ///
  /// Nama dan kata sandi boleh diubah bersamaan. Backend mewajibkan
  /// `current_password` bila `new_password` dikirim.
  Future<User> updateProfile({
    String? name,
    String? currentPassword,
    String? newPassword,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (newPassword != null && newPassword.isNotEmpty) {
      body['current_password'] = currentPassword ?? '';
      body['new_password'] = newPassword;
    }

    final data = Json.asMap(
      await _api.patch('/api/auth/me', body: body),
    );
    return User.fromJson(Json.asMap(data['user']));
  }

  AuthResult _keHasil(dynamic data) {
    final map = Json.asMap(data);
    return AuthResult(
      user: User.fromJson(Json.asMap(map['user'])),
      token: Json.text(map['token']),
    );
  }
}
