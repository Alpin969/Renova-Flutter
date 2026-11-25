/// Pembantu parsing nilai JSON dari PostgreSQL.
///
/// Kolom NUMERIC (harga, berat) dikirim driver `pg` sebagai teks agar
/// presisinya tidak hilang, sedangkan id dikirim sebagai angka. Keduanya
/// harus bisa dibaca tanpa melempar error.
class Json {
  const Json._();

  static double? toDouble(dynamic nilai) {
    if (nilai == null) return null;
    if (nilai is num) return nilai.toDouble();
    if (nilai is String) {
      final teks = nilai.trim();
      if (teks.isEmpty) return null;
      return double.tryParse(teks);
    }
    return null;
  }

  static int? toInt(dynamic nilai) {
    if (nilai == null) return null;
    if (nilai is int) return nilai;
    if (nilai is num) return nilai.toInt();
    if (nilai is String) return int.tryParse(nilai.trim());
    return null;
  }

  static String? toText(dynamic nilai) {
    if (nilai == null) return null;
    if (nilai is String) return nilai;
    return nilai.toString();
  }

  static String text(dynamic nilai, {String fallback = ''}) =>
      toText(nilai)?.trim() ?? fallback;

  static DateTime? toDate(dynamic nilai) {
    if (nilai == null) return null;
    if (nilai is DateTime) return nilai;
    if (nilai is String) return DateTime.tryParse(nilai);
    return null;
  }

  static Map<String, dynamic> asMap(dynamic nilai) {
    if (nilai is Map<String, dynamic>) return nilai;
    if (nilai is Map) return nilai.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> asMapList(dynamic nilai) {
    if (nilai is List) {
      return nilai.map(asMap).where((item) => item.isNotEmpty).toList();
    }
    return const <Map<String, dynamic>>[];
  }
}
