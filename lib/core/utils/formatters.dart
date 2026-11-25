/// Pemformatan angka dan tanggal dalam gaya Indonesia.
///
/// Ditulis manual (bukan memakai data locale intl) supaya hasilnya sama di
/// semua perangkat tanpa perlu memuat data locale saat aplikasi dibuka.
class Formats {
  const Formats._();

  static const List<String> _namaBulan = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _namaBulanPanjang = <String>[
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const List<String> _namaHari = <String>[
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  /// 25000 -> "Rp 25.000". Angka desimal dibulatkan ke rupiah terdekat.
  static String rupiah(num? nilai) {
    if (nilai == null || nilai.isNaN || nilai.isInfinite) return '—';
    final bulat = nilai.round();
    final negatif = bulat < 0;
    final teks = _kelompokkan(bulat.abs().toString());
    return negatif ? '-Rp $teks' : 'Rp $teks';
  }

  /// Angka dengan pemisah ribuan tanpa satuan, mis. "1.250".
  static String angka(num? nilai, {int desimal = 0}) {
    if (nilai == null || nilai.isNaN || nilai.isInfinite) return '—';
    if (desimal <= 0) return _kelompokkan(nilai.round().abs().toString());
    final teks = nilai.abs().toStringAsFixed(desimal);
    final bagian = teks.split('.');
    final bulat = _kelompokkan(bagian.first);
    return '${nilai < 0 ? '-' : ''}$bulat,${bagian.last}';
  }

  /// 2.5 -> "2,5 kg"
  static String berat(num? nilai) {
    if (nilai == null || nilai.isNaN || nilai.isInfinite) return '—';
    var teks = nilai.toStringAsFixed(2);
    if (teks.endsWith('0')) teks = teks.substring(0, teks.length - 1);
    if (teks.endsWith('0')) teks = teks.substring(0, teks.length - 1);
    if (teks.endsWith('.')) teks = teks.substring(0, teks.length - 1);
    return '${teks.replaceAll('.', ',')} kg';
  }

  /// "12 Nov 2026"
  static String tanggal(DateTime? waktu) {
    if (waktu == null) return '—';
    final lokal = waktu.toLocal();
    return '${lokal.day} ${_namaBulan[lokal.month - 1]} ${lokal.year}';
  }

  /// "12 November 2026"
  static String tanggalPanjang(DateTime? waktu) {
    if (waktu == null) return '—';
    final lokal = waktu.toLocal();
    return '${lokal.day} ${_namaBulanPanjang[lokal.month - 1]} ${lokal.year}';
  }

  static String hariTanggal(DateTime? waktu) {
    if (waktu == null) return '—';
    final lokal = waktu.toLocal();
    return '${_namaHari[lokal.weekday - 1]}, ${tanggal(lokal)}';
  }

  /// "12 Nov 2026, 14:05"
  static String tanggalJam(DateTime? waktu) {
    if (waktu == null) return '—';
    final lokal = waktu.toLocal();
    final jam = lokal.hour.toString().padLeft(2, '0');
    final menit = lokal.minute.toString().padLeft(2, '0');
    return '${tanggal(lokal)}, $jam:$menit';
  }

  /// "14:05"
  static String jam(DateTime? waktu) {
    if (waktu == null) return '—';
    final lokal = waktu.toLocal();
    return '${lokal.hour.toString().padLeft(2, '0')}:'
        '${lokal.minute.toString().padLeft(2, '0')}';
  }

  /// "2,5" untuk nilai di dalam input teks.
  static String isianAngka(num? nilai) {
    if (nilai == null || nilai.isNaN || nilai.isInfinite) return '';
    var teks = nilai.toStringAsFixed(2);
    while (teks.contains('.') && (teks.endsWith('0') || teks.endsWith('.'))) {
      teks = teks.substring(0, teks.length - 1);
    }
    return teks.replaceAll('.', ',');
  }

  /// Nomor pesanan yang mudah dibaca: id 12 -> "RNV-0012".
  static String nomorPesanan(int id) => 'RNV-${id.toString().padLeft(4, '0')}';

  static String _kelompokkan(String angkaTanpaTanda) {
    final buffer = StringBuffer();
    for (var i = 0; i < angkaTanpaTanda.length; i++) {
      final sisa = angkaTanpaTanda.length - i;
      buffer.write(angkaTanpaTanda[i]);
      if (sisa > 1 && sisa % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }
}
