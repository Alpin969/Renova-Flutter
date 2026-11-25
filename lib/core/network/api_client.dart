import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

/// Isi response API: `data` plus `meta` bila ada (mis. jumlah pada daftar).
class ApiEnvelope {
  const ApiEnvelope({this.data, this.meta});

  final dynamic data;
  final Map<String, dynamic>? meta;
}

/// Klien HTTP tunggal untuk seluruh aplikasi.
///
/// Semua permintaan melewati kelas ini supaya penanganan token, parsing
/// response, dan penerjemahan error hanya ditulis satu kali.
class ApiClient {
  ApiClient({
    http.Client? client,
    String Function()? tokenProvider,
    VoidCallback? onUnauthorized,
  })  : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? (() => ''),
        // Named parameter tidak bisa memakai initializing formal privat.
        // ignore: prefer_initializing_formals
        _onUnauthorized = onUnauthorized;

  final http.Client _client;

  /// Dibaca setiap kali ada permintaan, sehingga token terbaru selalu dipakai.
  final String Function() _tokenProvider;

  /// Dipanggil saat server menolak token yang kita kirim. Login biasa tidak
  /// memicunya, karena saat itu belum ada token yang dikirim.
  final VoidCallback? _onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String>? query}) async =>
      (await getEnvelope(path, query: query)).data;

  /// Seperti [get], tetapi ikut mengembalikan `meta` dari response.
  Future<ApiEnvelope> getEnvelope(
    String path, {
    Map<String, String>? query,
  }) async {
    return _kirim('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body}) async =>
      (await _kirim('POST', path, body: body)).data;

  Future<dynamic> put(String path, {Object? body}) async =>
      (await _kirim('PUT', path, body: body)).data;

  Future<dynamic> patch(String path, {Object? body}) async =>
      (await _kirim('PATCH', path, body: body)).data;

  Future<dynamic> delete(String path, {Object? body}) async =>
      (await _kirim('DELETE', path, body: body)).data;

  /// Mengirim satu berkas sebagai `multipart/form-data`.
  ///
  /// Nama field mengikuti backend: `photo` pada endpoint foto pesanan. Method
  /// juga mengikuti backend — unggah foto pesanan memakai PATCH, bukan POST.
  Future<dynamic> sendMultipart(
    String path, {
    String method = 'POST',
    required String field,
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final token = _tokenProvider();
    final request = http.MultipartRequest(method, _uri(path));
    _pasangHeader(request, token);

    request.files.add(
      http.MultipartFile.fromBytes(
        field,
        bytes,
        filename: filename,
        contentType: contentType == null ? null : MediaType.parse(contentType),
      ),
    );

    http.Response response;
    try {
      final streamed = await _client
          .send(request)
          .timeout(ApiConfig.batasWaktuPermintaan);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(
        message: 'Unggah foto terlalu lama. Periksa koneksi lalu coba lagi.',
        isTimeout: true,
      );
    } on http.ClientException catch (error) {
      throw _kesalahanJaringan(error.message);
    } catch (error) {
      throw _kesalahanJaringan(error.toString());
    }

    return _bacaAman(response, token).data;
  }

  void close() => _client.close();

  Future<ApiEnvelope> _kirim(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final token = _tokenProvider();
    final request = http.Request(method, _uri(path, query));
    _pasangHeader(request, token);

    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      final streamed = await _client
          .send(request)
          .timeout(ApiConfig.batasWaktuPermintaan);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(
        message: 'Server terlalu lama menjawab. Periksa koneksi lalu coba lagi.',
        isTimeout: true,
      );
    } on http.ClientException catch (error) {
      throw _kesalahanJaringan(error.message);
    } catch (error) {
      throw _kesalahanJaringan(error.toString());
    }

    return _bacaAman(response, token);
  }

  void _pasangHeader(http.BaseRequest request, String token) {
    request.headers['Accept'] = 'application/json';

    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Membaca response, sekaligus memberi tahu pemilik sesi bila token yang
  /// baru saja dikirim ternyata ditolak server.
  ApiEnvelope _bacaAman(http.Response response, String token) {
    try {
      return _bacaResponse(response);
    } on ApiException catch (error) {
      if (error.statusCode == 401 && token.isNotEmpty) {
        _onUnauthorized?.call();
      }
      rethrow;
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final dasar = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return dasar;
    return dasar.replace(queryParameters: query);
  }

  ApiEnvelope _bacaResponse(http.Response response) {
    final teks = utf8.decode(response.bodyBytes, allowMalformed: true);
    dynamic isi;

    if (teks.trim().isNotEmpty) {
      try {
        isi = jsonDecode(teks);
      } on FormatException {
        // Bukan JSON: hampir pasti bukan response API (mis. halaman error
        // proxy). Diterjemahkan menjadi pesan yang jujur, bukan "gagal".
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw ApiException(
            message: 'Server mengirim jawaban yang tidak dikenali.',
            statusCode: response.statusCode,
          );
        }
        throw ApiException(
          message: 'Server mengembalikan kesalahan (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (isi is Map<String, dynamic>) {
        return ApiEnvelope(
          data: isi['data'],
          meta: isi['meta'] is Map<String, dynamic>
              ? isi['meta'] as Map<String, dynamic>
              : null,
        );
      }
      return ApiEnvelope(data: isi);
    }

    if (isi is Map<String, dynamic>) {
      final pesan = isi['message'];
      throw ApiException(
        message: pesan is String && pesan.trim().isNotEmpty
            ? pesan
            : 'Permintaan tidak dapat diproses.',
        statusCode: response.statusCode,
        code: isi['error'] is String ? isi['error'] as String : null,
      );
    }

    throw ApiException(
      message: 'Permintaan tidak dapat diproses (HTTP ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  ApiException _kesalahanJaringan(String detail) {
    if (kDebugMode) {
      debugPrint('[api] Gagal menghubungi server: $detail');
    }
    return ApiException(
      message: 'Tidak dapat terhubung ke server. Periksa koneksi internet '
          'atau alamat server.',
      isNetwork: true,
    );
  }
}
