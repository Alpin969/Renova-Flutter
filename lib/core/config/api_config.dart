import 'package:flutter/foundation.dart';

/// Satu-satunya tempat alamat REST API RENOVA ditentukan.
///
/// Alamat produksi belum tersedia, jadi TIDAK ada alamat yang dikarang di
/// sini. Nilai bawaan hanya menunjuk server pengembangan di komputer sendiri.
/// Saat build ke perangkat nyata atau server, berikan alamat aslinya:
///
///   flutter run --dart-define=API_BASE_URL=https://api.contoh.com
///   flutter build apk --dart-define=API_BASE_URL=https://api.contoh.com
class ApiConfig {
  const ApiConfig._();

  static const String _dariEnv = String.fromEnvironment('API_BASE_URL');

  /// Apakah alamat API masih memakai nilai bawaan pengembangan.
  static bool get memakaiAlamatBawaan => _dariEnv.trim().isEmpty;

  static String get baseUrl {
    final dariEnv = _dariEnv.trim();
    if (dariEnv.isNotEmpty) return _rapikan(dariEnv);

    // Emulator Android tidak bisa menjangkau "localhost" komputer induk;
    // alamat khusus emulator untuk host adalah 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  /// Mengubah path relatif dari API (mis. `/uploads/foto.jpg`) menjadi URL
  /// lengkap. Backend menyimpan `photo_url` sebagai path relatif.
  static String? resolveUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final bersih = path.trim();
    if (bersih.startsWith('http://') || bersih.startsWith('https://')) {
      return bersih;
    }
    final dasar = Uri.parse('$baseUrl/');
    return dasar.resolve(bersih.startsWith('/') ? bersih.substring(1) : bersih).toString();
  }

  /// Batas unggah foto mengikuti backend: maksimal 2 MB, satu berkas.
  static const int batasUkuranFotoByte = 2 * 1024 * 1024;

  static const Duration batasWaktuPermintaan = Duration(seconds: 20);

  static String _rapikan(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
