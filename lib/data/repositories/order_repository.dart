import '../../core/network/api_client.dart';
import '../models/json.dart';
import '../models/order.dart';

class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  static const int _limitMaks = 100;

  /// GET /api/orders?status=&limit=&offset=
  ///
  /// Customer otomatis hanya menerima pesanannya sendiri; penyaringan itu
  /// dilakukan backend, bukan aplikasi.
  Future<OrderPage> list({String? status, int limit = 50, int offset = 0}) async {
    final query = <String, String>{
      'limit': '${limit.clamp(1, _limitMaks)}',
      'offset': '$offset',
    };
    if (status != null) query['status'] = status;

    final envelope = await _api.getEnvelope('/api/orders', query: query);
    final items = Json.asMapList(envelope.data).map(Order.fromJson).toList();

    return OrderPage(
      items: items,
      jumlah: Json.toInt(envelope.meta?['jumlah']),
    );
  }

  /// Mengambil pesanan per halaman sampai habis.
  ///
  /// Dipakai layar yang butuh angka ringkasan (dashboard admin). Batas
  /// [_maksHalaman] mencegah pengambilan tanpa ujung pada data besar; bila
  /// batas tercapai, pemanggil tahu datanya terpotong lewat [OrderList.hasil].
  Future<OrderList> listAll({String? status, int maksHalaman = 10}) async {
    final semua = <Order>[];
    var offset = 0;
    var terpotong = false;

    for (var halaman = 0; halaman < maksHalaman; halaman++) {
      final page = await list(status: status, limit: _limitMaks, offset: offset);
      semua.addAll(page.items);

      if (page.items.length < _limitMaks) {
        return OrderList(items: semua, terpotong: false);
      }

      offset += _limitMaks;
      terpotong = true;
    }

    return OrderList(items: semua, terpotong: terpotong);
  }

  /// Mengambil pesanan untuk beberapa status sekaligus, lalu menggabungkannya
  /// dalam satu daftar terurut dari yang terbaru.
  ///
  /// Dipakai layar yang menampilkan "pesanan aktif" (empat status berjalan)
  /// atau riwayat (selesai + dibatalkan), karena API hanya menerima satu
  /// nilai `status` per permintaan.
  Future<List<Order>> listByStatuses(
    List<String> statuses, {
    int limit = 50,
  }) async {
    if (statuses.isEmpty) return const <Order>[];

    final hasil = await Future.wait(
      statuses.map((status) => list(status: status, limit: limit)),
    );

    final semua = <Order>[];
    for (final page in hasil) {
      semua.addAll(page.items);
    }

    semua.sort((a, b) {
      final waktuA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final waktuB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return waktuB.compareTo(waktuA);
    });

    return semua;
  }

  /// GET /api/orders/:id
  Future<Order> detail(int id) async {
    return Order.fromJson(Json.asMap(await _api.get('/api/orders/$id')));
  }

  /// POST /api/orders (CUSTOMER)
  ///
  /// `payment_method` selalu dikirim karena aplikasi memilihkannya di
  /// halaman checkout. Backend mencatat CASH sebagai UNPAID dan metode lain
  /// sebagai PAID (pembayaran masih simulasi).
  Future<Order> create({
    required int serviceId,
    required double estimatedWeight,
    required String paymentMethod,
  }) async {
    final data = Json.asMap(
      await _api.post(
        '/api/orders',
        body: <String, dynamic>{
          'service_id': serviceId,
          'estimated_weight': estimatedWeight,
          'payment_method': paymentMethod,
        },
      ),
    );
    return Order.fromJson(data);
  }

  /// PATCH /api/orders/:id/foto — multipart/form-data, field "photo".
  Future<Order> uploadPhoto(
    int id, {
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final data = Json.asMap(
      await _api.sendMultipart(
        '/api/orders/$id/foto',
        method: 'PATCH',
        field: 'photo',
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      ),
    );
    return Order.fromJson(data);
  }

  /// DELETE /api/orders/:id/foto
  Future<Order> deletePhoto(int id) async {
    final data = Json.asMap(await _api.delete('/api/orders/$id/foto'));
    return Order.fromJson(data);
  }

  /// PATCH /api/orders/:id/batal
  Future<Order> cancel(int id) async {
    final data = Json.asMap(await _api.patch('/api/orders/$id/batal'));
    return Order.fromJson(data);
  }

  /// PATCH /api/orders/:id/status (ADMIN)
  Future<Order> updateStatus(int id, String status) async {
    final data = Json.asMap(
      await _api.patch(
        '/api/orders/$id/status',
        body: <String, dynamic>{'status': status},
      ),
    );
    return Order.fromJson(data);
  }

  /// PATCH /api/orders/:id/berat-asli (ADMIN)
  ///
  /// Harga akhir dihitung backend dari berat asli dan harga per kg pesanan;
  /// aplikasi hanya menampilkan nilai yang dikirim balik server.
  Future<Order> setActualWeight(int id, double actualWeight) async {
    final data = Json.asMap(
      await _api.patch(
        '/api/orders/$id/berat-asli',
        body: <String, dynamic>{'actual_weight': actualWeight},
      ),
    );
    return Order.fromJson(data);
  }

  /// PATCH /api/orders/:id/bayar (ADMIN) — konfirmasi pembayaran tunai.
  Future<Order> confirmPayment(int id) async {
    final data = Json.asMap(await _api.patch('/api/orders/$id/bayar'));
    return Order.fromJson(data);
  }
}

/// Hasil pengambilan daftar penuh, dengan penanda bila terpotong batas.
class OrderList {
  const OrderList({required this.items, required this.terpotong});

  final List<Order> items;
  final bool terpotong;
}
