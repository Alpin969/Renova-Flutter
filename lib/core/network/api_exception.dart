/// Kesalahan yang berasal dari REST API RENOVA atau dari jaringan.
///
/// Pesan dari backend sudah ditulis untuk dibaca pengguna (mis. "Ukuran foto
/// maksimal 2 MB."), jadi pesan itulah yang ditampilkan — bukan pesan teknis
/// buatan aplikasi.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.isNetwork = false,
    this.isTimeout = false,
  });

  final String message;
  final int? statusCode;

  /// Kode dari field `error` pada response backend, mis. `TOKEN_EXPIRED`.
  final String? code;

  /// True bila permintaan tidak pernah sampai ke server.
  final bool isNetwork;
  final bool isTimeout;

  /// True bila sesi sudah tidak berlaku dan pengguna harus login ulang.
  /// Backend memakai 401 untuk token hilang, tidak sah, kedaluwarsa, atau
  /// akunnya sudah dihapus.
  bool get sesiBerakhir =>
      statusCode == 401 &&
      (code == 'TOKEN_MISSING' ||
          code == 'TOKEN_INVALID' ||
          code == 'TOKEN_EXPIRED' ||
          code == 'ACCOUNT_NOT_FOUND' ||
          code == null);

  @override
  String toString() => 'ApiException($statusCode/$code): $message';
}

/// Pesan yang aman ditampilkan ke pengguna untuk kesalahan apa pun.
///
/// Kesalahan yang tidak dikenal tidak dibocorkan apa adanya (bisa memuat
/// detail teknis); pengguna diberi pesan umum dan diminta mencoba lagi.
String pesanKesalahan(Object error) {
  if (error is ApiException) return error.message;
  return 'Terjadi kesalahan yang tidak terduga. Coba lagi beberapa saat lagi.';
}
