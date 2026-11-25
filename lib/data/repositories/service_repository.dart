import '../../core/network/api_client.dart';
import '../models/json.dart';
import '../models/service_item.dart';

class ServiceRepository {
  ServiceRepository(this._api);

  final ApiClient _api;

  /// GET /api/services?search=
  Future<List<ServiceItem>> list({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final data = await _api.get('/api/services', query: query);
    return Json.asMapList(data).map(ServiceItem.fromJson).toList();
  }

  /// GET /api/services/:id
  Future<ServiceItem> detail(int id) async {
    final data = Json.asMap(await _api.get('/api/services/$id'));
    return ServiceItem.fromJson(data);
  }

  /// POST /api/services (ADMIN)
  Future<ServiceItem> create({
    required String name,
    required String duration,
    required double pricePerKg,
    String? description,
  }) async {
    final data = Json.asMap(
      await _api.post(
        '/api/services',
        body: <String, dynamic>{
          'name': name.trim(),
          'duration': duration.trim(),
          'price_per_kg': pricePerKg,
          'description': _deskripsi(description),
        },
      ),
    );
    return ServiceItem.fromJson(data);
  }

  /// PUT /api/services/:id (ADMIN)
  Future<ServiceItem> update(
    int id, {
    required String name,
    required String duration,
    required double pricePerKg,
    String? description,
  }) async {
    final data = Json.asMap(
      await _api.put(
        '/api/services/$id',
        body: <String, dynamic>{
          'name': name.trim(),
          'duration': duration.trim(),
          'price_per_kg': pricePerKg,
          'description': _deskripsi(description),
        },
      ),
    );
    return ServiceItem.fromJson(data);
  }

  /// DELETE /api/services/:id (ADMIN)
  ///
  /// Backend menolak (409 SERVICE_IN_USE) bila layanan sudah dipakai
  /// pesanan; penolakan itu diteruskan apa adanya sebagai ApiException.
  Future<void> remove(int id) async {
    await _api.delete('/api/services/$id');
  }

  /// Deskripsi kosong dikirim sebagai null, sesuai cara backend mengosongkan
  /// kolom description.
  String? _deskripsi(String? nilai) {
    final teks = nilai?.trim() ?? '';
    return teks.isEmpty ? null : teks;
  }
}
