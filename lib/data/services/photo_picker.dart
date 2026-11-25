import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Foto yang sudah dipilih pengguna dan lolos pemeriksaan format/ukuran.
class PickedPhoto {
  const PickedPhoto({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

/// Kesalahan pemilihan foto yang pesannya layak ditampilkan ke pengguna.
class PhotoPickException implements Exception {
  PhotoPickException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Memilih foto pesanan dari galeri atau kamera, lalu memeriksanya sesuai
/// batas backend: JPEG/PNG/WebP dan maksimal 2 MB.
class PhotoPicker {
  PhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Batas ukuran sama dengan `multer` di backend.
  static const int batasByte = 2 * 1024 * 1024;

  Future<PickedPhoto?> ambil(ImageSource sumber) async {
    final XFile? berkas;
    try {
      berkas = await _picker.pickImage(
        source: sumber,
        // Diperkecil sebelum dikirim supaya foto kamera ponsel tidak
        // melewati batas 2 MB. Kualitas 88 masih nyaman dilihat.
        maxWidth: 1600,
        imageQuality: 88,
      );
    } catch (error) {
      throw PhotoPickException(
        'Foto tidak dapat dipilih. Periksa izin galeri/kamera pada perangkat.',
      );
    }

    if (berkas == null) return null;

    final bytes = await berkas.readAsBytes();
    if (bytes.isEmpty) {
      throw PhotoPickException('Berkas foto kosong. Pilih foto lain.');
    }

    if (bytes.length > batasByte) {
      throw PhotoPickException(
        'Ukuran foto melebihi 2 MB. Pilih foto yang lebih kecil.',
      );
    }

    final jenis = _deteksiJenis(bytes);
    if (jenis == null) {
      throw PhotoPickException(
        'Format foto harus JPEG, PNG, atau WebP.',
      );
    }

    return PickedPhoto(
      bytes: bytes,
      filename: 'pesanan.${jenis.ekstensi}',
      contentType: jenis.mime,
    );
  }

  /// Menentukan jenis berkas dari beberapa byte pertama, bukan dari nama
  /// berkas — nama dari galeri tidak selalu mencerminkan isinya.
  _JenisFoto? _deteksiJenis(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return const _JenisFoto('jpg', 'image/jpeg');
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return const _JenisFoto('png', 'image/png');
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46 && // F
        bytes[8] == 0x57 && // W
        bytes[9] == 0x45 && // E
        bytes[10] == 0x42 && // B
        bytes[11] == 0x50) {
      return const _JenisFoto('webp', 'image/webp');
    }

    return null;
  }
}

class _JenisFoto {
  const _JenisFoto(this.ekstensi, this.mime);

  final String ekstensi;
  final String mime;
}
