import 'json.dart';

/// Layanan laundry dari `/api/services`.
class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.pricePerKg,
    required this.duration,
    this.description,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? description;
  final double pricePerKg;

  /// Durasi ditulis sebagai teks oleh backend, mis. "2 hari".
  final String duration;
  final DateTime? createdAt;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: Json.toInt(json['id']) ?? 0,
      name: Json.text(json['name'], fallback: 'Layanan'),
      description: Json.toText(json['description']),
      pricePerKg: Json.toDouble(json['price_per_kg']) ?? 0,
      duration: Json.text(json['duration'], fallback: '—'),
      createdAt: Json.toDate(json['created_at']),
    );
  }

  String get deskripsiTampil {
    final teks = description?.trim() ?? '';
    return teks.isEmpty ? 'Belum ada deskripsi untuk layanan ini.' : teks;
  }
}
