/// Menyimpan token yang sedang dipakai di memori.
///
/// Dipisah dari penyimpanan permanen supaya klien HTTP bisa membaca token
/// terbaru tanpa perlu tahu soal proses login.
class TokenHolder {
  String? token;

  void set(String? nilai) => token = nilai;

  void clear() => token = null;

  bool get terisi => token != null && token!.isNotEmpty;
}
