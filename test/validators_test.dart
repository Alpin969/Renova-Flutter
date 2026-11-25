import 'package:flutter_test/flutter_test.dart';
import 'package:renova/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('menerima email wajar', () {
      expect(Validators.email('budi@mail.com'), isNull);
      expect(Validators.email('  budi@mail.com  '), isNull);
    });

    test('menolak email kosong atau tanpa domain', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('budi'), isNotNull);
      expect(Validators.email('budi@mail'), isNotNull);
      expect(Validators.email('budi @mail.com'), isNotNull);
    });
  });

  group('Validators.sandiBaru', () {
    test('batas minimal 8 karakter sesuai backend', () {
      expect(Validators.sandiBaru('1234567'), isNotNull);
      expect(Validators.sandiBaru('12345678'), isNull);
    });

    test('menolak kata sandi lebih dari 72 karakter', () {
      expect(Validators.sandiBaru('a' * 73), isNotNull);
      expect(Validators.sandiBaru('a' * 72), isNull);
    });
  });

  group('Validators.berat', () {
    test('menerima angka dengan koma maupun titik', () {
      expect(Validators.berat('2,5'), isNull);
      expect(Validators.berat('2.5'), isNull);
      expect(Validators.berat('0,01'), isNull);
    });

    test('menolak kosong, nol, negatif, dan bukan angka', () {
      expect(Validators.berat(''), isNotNull);
      expect(Validators.berat('0'), isNotNull);
      expect(Validators.berat('-1'), isNotNull);
      expect(Validators.berat('dua'), isNotNull);
    });
  });

  group('Validators.harga', () {
    test('menerima harga dengan pemisah ribuan', () {
      expect(Validators.harga('7000'), isNull);
      expect(Validators.harga('7.000'), isNull);
    });

    test('menolak nol dan bukan angka', () {
      expect(Validators.harga('0'), isNotNull);
      expect(Validators.harga('murah'), isNotNull);
    });
  });

  group('Validators.keAngkaBerat', () {
    test('koma maupun titik sama-sama desimal', () {
      expect(Validators.keAngkaBerat('2,5'), 2.5);
      expect(Validators.keAngkaBerat('2.5'), 2.5);
      expect(Validators.keAngkaBerat('2.75'), 2.75);
      expect(Validators.keAngkaBerat('10'), 10);
    });

    test('mengembalikan null untuk isian tidak sah', () {
      expect(Validators.keAngkaBerat('dua'), isNull);
      expect(Validators.keAngkaBerat(''), isNull);
      expect(Validators.keAngkaBerat(null), isNull);
    });
  });

  group('Validators.keAngkaHarga', () {
    test('titik adalah pemisah ribuan', () {
      expect(Validators.keAngkaHarga('7.000'), 7000);
      expect(Validators.keAngkaHarga('7000'), 7000);
      expect(Validators.keAngkaHarga('1.250.000'), 1250000);
      expect(Validators.keAngkaHarga('7.000,50'), 7000.5);
    });

    test('mengembalikan null untuk isian tidak sah', () {
      expect(Validators.keAngkaHarga('murah'), isNull);
      expect(Validators.keAngkaHarga(''), isNull);
    });
  });

  group('Validators.konfirmasiSandi', () {
    test('menolak kata sandi yang belum sama', () {
      expect(Validators.konfirmasiSandi('abc', 'abd'), isNotNull);
      expect(Validators.konfirmasiSandi('abc', 'abc'), isNull);
    });
  });
}
