import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan token JWT.
///
/// Memakai penyimpanan aman milik sistem (Keystore/Keychain; di web memakai
/// WebCrypto di atas localStorage). Hanya token yang disimpan — kata sandi
/// tidak pernah ditulis ke perangkat.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;

  static const String _kunciToken = 'renova_token';

  Future<String?> read() async {
    try {
      final nilai = await _storage.read(key: _kunciToken);
      if (nilai == null || nilai.isEmpty) return null;
      return nilai;
    } catch (error) {
      // Penyimpanan bisa gagal (mis. web tanpa HTTPS). Sesi dianggap tidak
      // ada, dan pengguna diminta login — bukan aplikasi yang berhenti.
      debugPrint('[token] Gagal membaca token: $error');
      return null;
    }
  }

  Future<void> write(String token) async {
    try {
      await _storage.write(key: _kunciToken, value: token);
    } catch (error) {
      debugPrint('[token] Gagal menyimpan token: $error');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kunciToken);
    } catch (error) {
      debugPrint('[token] Gagal menghapus token: $error');
    }
  }
}
