import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import 'loadable.dart';

/// Mengelola satu potongan data asinkron beserta keadaan memuat/gagalnya.
///
/// Hasil permintaan lama diabaikan bila ada permintaan yang lebih baru, jadi
/// data yang tampil selalu berasal dari permintaan terakhir — bukan campuran
/// keduanya.
class DataController<T> extends ChangeNotifier {
  DataController(this._muat);

  final Future<T> Function() _muat;

  Loadable<T> _state = Loading<T>();
  int _permintaan = 0;
  bool _dibuang = false;

  Loadable<T> get state => _state;

  /// [showLoading] dimatikan saat penyegaran sudah punya penanda sendiri
  /// (mis. kursor tarik-untuk-menyegarkan).
  Future<void> load({bool showLoading = true}) async {
    final id = ++_permintaan;

    if (showLoading && !_dibuang) {
      _state = Loading<T>();
      notifyListeners();
    }

    try {
      final data = await _muat();
      if (_dibuang || id != _permintaan) return;
      _state = Ready<T>(data);
    } catch (error) {
      if (_dibuang || id != _permintaan) return;
      _state = Failure<T>(pesanKesalahan(error));
    }

    if (!_dibuang) notifyListeners();
  }

  /// Mengganti isi tanpa meminta ulang ke server, untuk respons yang sudah
  /// membawa data terbaru.
  void gantiData(T data) {
    if (_dibuang) return;
    _permintaan++;
    _state = Ready<T>(data);
    notifyListeners();
  }

  @override
  void dispose() {
    _dibuang = true;
    super.dispose();
  }
}
