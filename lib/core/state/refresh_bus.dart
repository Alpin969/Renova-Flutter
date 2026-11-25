import 'package:flutter/foundation.dart';

/// Penanda bahwa data pesanan berubah (dibuat, dibatalkan, statusnya diubah).
///
/// Setiap tab mendengarkan sinyal ini dan memuat ulang datanya, sehingga tab
/// yang sudah terbuka tidak menampilkan keadaan lama setelah ada tindakan di
/// tab lain.
class RefreshBus extends ChangeNotifier {
  int _versi = 0;

  int get versi => _versi;

  void tandaBerubah() {
    _versi++;
    notifyListeners();
  }
}
