/// Aturan validasi yang mencerminkan aturan backend RENOVA.
///
/// Batasnya diambil dari `src/utils/validate.js` dan controller backend,
/// supaya pesan kesalahan muncul sebelum request dikirim — bukan sesudah.
class Validators {
  const Validators._();

  static const int namaMin = 1;
  static const int namaMaks = 100;
  static const int sandiMin = 8;
  static const int sandiMaks = 72; // bcrypt hanya memakai 72 byte pertama
  static const int layananNamaMaks = 100;
  static const int layananDeskripsiMaks = 2000;
  static const int layananDurasiMaks = 50;
  static const double beratMin = 0.01;
  static const double beratMaks = 999999;
  static const double hargaMin = 0.01;
  static const double hargaMaks = 99999999;

  static final RegExp _polaEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? nama(String? nilai) {
    final teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Nama wajib diisi.';
    if (teks.length > namaMaks) return 'Nama maksimal $namaMaks karakter.';
    return null;
  }

  static String? email(String? nilai) {
    final teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Email wajib diisi.';
    if (teks.length < 3) return 'Email terlalu pendek.';
    if (teks.length > 100) return 'Email maksimal 100 karakter.';
    if (!_polaEmail.hasMatch(teks)) return 'Format email belum benar, mis. nama@email.com.';
    return null;
  }

  static String? sandiBaru(String? nilai) {
    final teks = nilai ?? '';
    if (teks.isEmpty) return 'Kata sandi wajib diisi.';
    if (teks.length < sandiMin) return 'Kata sandi minimal $sandiMin karakter.';
    if (teks.length > sandiMaks) return 'Kata sandi maksimal $sandiMaks karakter.';
    return null;
  }

  static String? sandiMasuk(String? nilai) {
    if ((nilai ?? '').isEmpty) return 'Kata sandi wajib diisi.';
    return null;
  }

  static String? konfirmasiSandi(String? nilai, String asli) {
    if ((nilai ?? '').isEmpty) return 'Ulangi kata sandi untuk memastikan.';
    if (nilai != asli) return 'Kata sandi belum sama.';
    return null;
  }

  static String? berat(String? nilai) {
    final teks = (nilai ?? '').trim().replaceAll(',', '.');
    if (teks.isEmpty) return 'Estimasi berat wajib diisi.';
    final angka = double.tryParse(teks);
    if (angka == null) return 'Berat harus berupa angka, mis. 2,5.';
    if (angka < beratMin) return 'Berat minimal 0,01 kg.';
    if (angka > beratMaks) return 'Berat terlalu besar.';
    return null;
  }

  static String? harga(String? nilai) {
    final teks = (nilai ?? '').trim().replaceAll('.', '').replaceAll(',', '.');
    if (teks.isEmpty) return 'Harga per kg wajib diisi.';
    final angka = double.tryParse(teks);
    if (angka == null) return 'Harga harus berupa angka.';
    if (angka < hargaMin) return 'Harga harus lebih dari 0.';
    if (angka > hargaMaks) return 'Harga terlalu besar.';
    return null;
  }

  static String? durasi(String? nilai) {
    final teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Durasi wajib diisi, mis. "2 hari".';
    if (teks.length > layananDurasiMaks) {
      return 'Durasi maksimal $layananDurasiMaks karakter.';
    }
    return null;
  }

  static String? namaLayanan(String? nilai) {
    final teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Nama layanan wajib diisi.';
    if (teks.length > layananNamaMaks) {
      return 'Nama layanan maksimal $layananNamaMaks karakter.';
    }
    return null;
  }

  static String? deskripsiLayanan(String? nilai) {
    final teks = (nilai ?? '').trim();
    if (teks.length > layananDeskripsiMaks) {
      return 'Deskripsi maksimal $layananDeskripsiMaks karakter.';
    }
    return null;
  }

  /// Mengubah isian berat menjadi angka.
  ///
  /// Berat jarang ditulis dengan pemisah ribuan, sedangkan titik maupun koma
  /// sama-sama dipakai sebagai desimal ("2.5" dan "2,5"). Karena itu titik
  /// TIDAK dibuang di sini — berbeda dengan [keAngkaHarga].
  static double? keAngkaBerat(String? nilai) {
    if (nilai == null) return null;
    return double.tryParse(nilai.trim().replaceAll(',', '.'));
  }

  /// Mengubah isian harga menjadi angka.
  ///
  /// Harga ditulis dengan titik sebagai pemisah ribuan ("7.000") dan koma
  /// sebagai desimal ("7.000,50"), jadi titik dibuang lebih dulu.
  static double? keAngkaHarga(String? nilai) {
    if (nilai == null) return null;
    final teks = nilai.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(teks);
  }
}
