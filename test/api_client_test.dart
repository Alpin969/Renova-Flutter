import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:renova/core/network/api_client.dart';
import 'package:renova/core/network/api_exception.dart';
import 'package:renova/data/repositories/order_repository.dart';

/// Klien HTTP palsu yang merekam permintaan dan membalas dengan isi tetap.
///
/// Dipakai untuk memastikan aplikasi memakai method, path, dan header yang
/// benar-benar diterima backend — hal yang tidak bisa dibuktikan oleh tes
/// widget biasa.
class _KlienPerekam extends http.BaseClient {
  _KlienPerekam({required this.balas});

  final http.Response Function(http.BaseRequest request) balas;
  final List<http.BaseRequest> permintaan = [];
  final List<String> isi = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    permintaan.add(request);

    if (request is http.MultipartRequest) {
      isi.add(request.files.map((f) => '${f.field}:${f.filename}').join(','));
    } else if (request is http.Request) {
      isi.add(request.body);
    }

    final response = balas(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

Map<String, dynamic> _pesananJson({String? foto}) => <String, dynamic>{
      'id': 7,
      'user_id': 3,
      'customer_name': 'Budi Santoso',
      'service_id': 1,
      'service_name': 'Cuci Kering',
      'estimated_weight': '2.50',
      'actual_weight': null,
      'price_per_kg': '7000.00',
      'total_price': null,
      'status': 'PENDING_CONFIRMATION',
      'photo_url': foto,
      'created_at': '2026-11-12T07:05:00.000Z',
      'payment_method': 'CASH',
      'payment_status': 'UNPAID',
      'paid_at': null,
    };

void main() {
  group('OrderRepository.uploadPhoto', () {
    test('mengirim PATCH multipart ke endpoint foto dengan field photo',
        () async {
      // Backend mendaftarkan unggah foto sebagai PATCH /api/orders/:id/foto.
      // Tes ini gagal bila klien kembali memakai POST.
      final klien = _KlienPerekam(
        balas: (_) => http.Response(
          jsonEncode({
            'success': true,
            'message': 'Foto diunggah.',
            'data': _pesananJson(foto: '/uploads/baru.jpg'),
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final api = ApiClient(client: klien, tokenProvider: () => 'token-uji');
      final repo = OrderRepository(api);

      final hasil = await repo.uploadPhoto(
        7,
        bytes: <int>[0xFF, 0xD8, 0xFF, 0x01],
        filename: 'pesanan.jpg',
        contentType: 'image/jpeg',
      );

      expect(klien.permintaan, hasLength(1));
      final request = klien.permintaan.single;

      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/orders/7/foto');
      expect(request.headers['Authorization'], 'Bearer token-uji');
      expect(klien.isi.single, 'photo:pesanan.jpg');
      expect(hasil.photoUrl, endsWith('/uploads/baru.jpg'));
    });
  });

  group('OrderRepository.deletePhoto', () {
    test('memakai DELETE pada endpoint foto', () async {
      final klien = _KlienPerekam(
        balas: (_) => http.Response(
          jsonEncode({
            'success': true,
            'message': 'Foto dihapus.',
            'data': _pesananJson(),
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final api = ApiClient(client: klien, tokenProvider: () => 'token-uji');
      await OrderRepository(api).deletePhoto(7);

      expect(klien.permintaan.single.method, 'DELETE');
      expect(klien.permintaan.single.url.path, '/api/orders/7/foto');
    });
  });

  group('ApiClient', () {
    test('menyertakan Bearer token pada permintaan biasa', () async {
      final klien = _KlienPerekam(
        balas: (_) => http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': <String>[]}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final api = ApiClient(client: klien, tokenProvider: () => 'token-uji');
      await api.get('/api/orders');

      expect(klien.permintaan.single.headers['Authorization'], 'Bearer token-uji');
      expect(klien.permintaan.single.headers['Accept'], 'application/json');
    });

    test('tanpa token tidak mengirim header Authorization', () async {
      final klien = _KlienPerekam(
        balas: (_) => http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': <String>[]}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      await ApiClient(client: klien).get('/api/services');

      expect(
        klien.permintaan.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('menerjemahkan penolakan server menjadi ApiException dengan kode',
        () async {
      final klien = _KlienPerekam(
        balas: (_) => http.Response(
          jsonEncode({
            'success': false,
            'message': 'Pesanan yang sedang diproses tidak dapat dibatalkan.',
            'error': 'CANCEL_NOT_ALLOWED',
          }),
          403,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final api = ApiClient(client: klien, tokenProvider: () => 'token-uji');

      await expectLater(
        api.patch('/api/orders/7/batal'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.code, 'code', 'CANCEL_NOT_ALLOWED')
              .having((e) => e.message, 'message', contains('tidak dapat')),
        ),
      );
    });

    test('memberi tahu sesi saat token ditolak server', () async {
      var sesiHabis = false;

      final klien = _KlienPerekam(
        balas: (_) => http.Response(
          jsonEncode({
            'success': false,
            'message': 'Token sudah kedaluwarsa.',
            'error': 'TOKEN_EXPIRED',
          }),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final api = ApiClient(
        client: klien,
        tokenProvider: () => 'token-lama',
        onUnauthorized: () => sesiHabis = true,
      );

      await expectLater(
        api.get('/api/auth/me'),
        throwsA(isA<ApiException>()),
      );
      expect(sesiHabis, isTrue);
    });

    test('token ditolak saat belum ada token tidak mengakhiri sesi', () async {
      var sesiHabis = false;

      final klien = _KlienPerekam(
        balas: (_) => http.Response(
          jsonEncode({
            'success': false,
            'message': 'Email atau kata sandi salah.',
            'error': 'INVALID_CREDENTIALS',
          }),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final api = ApiClient(
        client: klien,
        onUnauthorized: () => sesiHabis = true,
      );

      await expectLater(
        api.post('/api/auth/login', body: {'email': 'a@b.c', 'password': 'x'}),
        throwsA(isA<ApiException>()),
      );
      expect(sesiHabis, isFalse);
    });
  });
}
