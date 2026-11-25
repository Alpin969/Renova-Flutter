import 'package:flutter/foundation.dart';

import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/token_holder.dart';
import '../../data/services/token_storage.dart';
import '../network/api_exception.dart';

/// Tahap sesi yang menentukan layar mana yang ditampilkan aplikasi.
enum SessionStatus {
  /// Token di perangkat sedang diperiksa ke server.
  memuat,

  /// Token ada, tetapi server belum bisa dihubungi untuk memeriksanya.
  gagalMemuat,

  /// Belum masuk.
  tamu,

  /// Sudah masuk dan datanya sudah dibaca dari `/api/auth/me`.
  masuk,
}

/// Pemegang keadaan autentikasi: token, akun yang sedang masuk, dan pesan
/// yang perlu ditampilkan pada layar login.
class SessionController extends ChangeNotifier {
  SessionController({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
    required TokenHolder tokenHolder,
  })  : _auth = authRepository,
        _storage = tokenStorage,
        _holder = tokenHolder;

  final AuthRepository _auth;
  final TokenStorage _storage;
  final TokenHolder _holder;

  SessionStatus _status = SessionStatus.memuat;
  User? _user;
  String? _pesanGagalPulih;
  String? _pesanSesi;
  String? _pesanAksi;
  bool _sedangProses = false;

  /// Dipanggil saat sesi berakhir agar layar yang sedang terbuka ditutup.
  VoidCallback? onSesiSelesai;

  SessionStatus get status => _status;
  User? get user => _user;
  bool get sedangProses => _sedangProses;

  /// Alasan sesi tidak bisa dipulihkan saat aplikasi dibuka.
  String? get pesanGagalPulih => _pesanGagalPulih;

  /// Pemberitahuan di layar login, mis. setelah sesi berakhir.
  String? get pesanSesi => _pesanSesi;

  /// Kesalahan dari percobaan login atau daftar terakhir.
  String? get pesanAksi => _pesanAksi;

  /// Memeriksa token yang tersimpan saat aplikasi dibuka.
  Future<void> pulihkanSesi() async {
    _status = SessionStatus.memuat;
    _pesanGagalPulih = null;
    notifyListeners();

    final token = await _storage.read();
    if (token == null || token.isEmpty) {
      _holder.clear();
      _status = SessionStatus.tamu;
      notifyListeners();
      return;
    }

    _holder.set(token);

    try {
      _user = await _auth.me();
      _status = SessionStatus.masuk;
      notifyListeners();
    } on ApiException catch (error) {
      _holder.clear();

      // Server hanya belum bisa dihubungi: token belum tentu salah, jadi
      // sesi tidak dihapus. Pengguna ditawari mencoba lagi.
      if (error.isNetwork || error.isTimeout) {
        _pesanGagalPulih = error.message;
        _status = SessionStatus.gagalMemuat;
        notifyListeners();
        return;
      }

      await _storage.clear();
      _status = SessionStatus.tamu;
      _pesanSesi = error.code == 'TOKEN_EXPIRED'
          ? 'Sesi sebelumnya sudah berakhir. Silakan masuk kembali.'
          : null;
      notifyListeners();
    }
  }

  Future<bool> masuk({required String email, required String password}) async {
    _sedangProses = true;
    _pesanAksi = null;
    _pesanSesi = null;
    notifyListeners();

    try {
      final hasil = await _auth.login(email: email, password: password);
      await _terapkanHasilMasuk(hasil.user, hasil.token);
      return true;
    } on ApiException catch (error) {
      _pesanAksi = error.message;
      return false;
    } finally {
      _sedangProses = false;
      notifyListeners();
    }
  }

  Future<bool> daftar({
    required String name,
    required String email,
    required String password,
  }) async {
    _sedangProses = true;
    _pesanAksi = null;
    _pesanSesi = null;
    notifyListeners();

    try {
      final hasil = await _auth.register(
        name: name,
        email: email,
        password: password,
      );
      await _terapkanHasilMasuk(hasil.user, hasil.token);
      return true;
    } on ApiException catch (error) {
      _pesanAksi = error.message;
      return false;
    } finally {
      _sedangProses = false;
      notifyListeners();
    }
  }

  Future<void> keluar() async {
    _holder.clear();
    await _storage.clear();
    _user = null;
    _status = SessionStatus.tamu;
    _pesanAksi = null;
    _pesanSesi = 'Anda sudah keluar dari akun.';
    onSesiSelesai?.call();
    notifyListeners();
  }

  /// Dipanggil klien HTTP ketika server menolak token yang sedang dipakai.
  void sesiHabis() {
    if (_status == SessionStatus.tamu) return;

    _holder.clear();
    _storage.clear();
    _user = null;
    _status = SessionStatus.tamu;
    _pesanAksi = null;
    _pesanSesi = 'Sesi Anda sudah berakhir. Silakan masuk kembali.';
    onSesiSelesai?.call();
    notifyListeners();
  }

  /// Menyimpan akun terbaru setelah profil diubah.
  void perbaruiUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> _terapkanHasilMasuk(User user, String token) async {
    _holder.set(token);
    await _storage.write(token);
    _user = user;
    _status = SessionStatus.masuk;
    _pesanAksi = null;
  }
}
