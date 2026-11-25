import 'package:flutter_test/flutter_test.dart';
import 'package:renova/core/utils/formatters.dart';

void main() {
  group('Formats.rupiah', () {
    test('memberi pemisah ribuan dan awalan Rp', () {
      expect(Formats.rupiah(25000), 'Rp 25.000');
      expect(Formats.rupiah(7000), 'Rp 7.000');
      expect(Formats.rupiah(0), 'Rp 0');
    });

    test('membulatkan desimal ke rupiah terdekat', () {
      expect(Formats.rupiah(2500.4), 'Rp 2.500');
      expect(Formats.rupiah(2500.6), 'Rp 2.501');
    });

    test('menangani angka besar dan negatif', () {
      expect(Formats.rupiah(1250000), 'Rp 1.250.000');
      expect(Formats.rupiah(-5000), '-Rp 5.000');
    });

    test('nilai kosong menjadi tanda hubung, bukan nol palsu', () {
      expect(Formats.rupiah(null), '—');
    });
  });

  group('Formats.berat', () {
    test('memakai koma dan satuan kg', () {
      expect(Formats.berat(2.5), '2,5 kg');
      expect(Formats.berat(2.0), '2 kg');
      expect(Formats.berat(2.75), '2,75 kg');
    });

    test('nilai kosong menjadi tanda hubung', () {
      expect(Formats.berat(null), '—');
    });
  });

  group('Formats.tanggal', () {
    test('memakai nama bulan Indonesia', () {
      final waktu = DateTime(2026, 11, 12, 14, 5);
      expect(Formats.tanggal(waktu), '12 Nov 2026');
      expect(Formats.tanggalPanjang(waktu), '12 November 2026');
      expect(Formats.tanggalJam(waktu), '12 Nov 2026, 14:05');
    });

    test('nilai kosong menjadi tanda hubung', () {
      expect(Formats.tanggal(null), '—');
    });
  });

  group('Formats.nomorPesanan', () {
    test('memberi awalan dan angka empat digit', () {
      expect(Formats.nomorPesanan(12), 'RNV-0012');
      expect(Formats.nomorPesanan(12345), 'RNV-12345');
    });
  });

  group('Formats.isianAngka', () {
    test('membuang nol desimal yang tidak perlu', () {
      expect(Formats.isianAngka(7000), '7000');
      expect(Formats.isianAngka(2.50), '2,5');
      expect(Formats.isianAngka(2.75), '2,75');
    });
  });
}
