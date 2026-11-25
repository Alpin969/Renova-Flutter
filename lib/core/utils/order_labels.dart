/// Pemetaan nilai status dan metode pembayaran dari API ke teks yang
/// dipahami pengguna.
///
/// Nilai asli API TIDAK diubah dan tidak ada status baru yang dibuat di
/// Flutter: yang berubah hanya label yang ditampilkan.
class OrderLabels {
  const OrderLabels._();

  // Enam status pesanan, persis seperti di backend.
  static const String pendingConfirmation = 'PENDING_CONFIRMATION';
  static const String confirmed = 'CONFIRMED';
  static const String washing = 'WASHING';
  static const String readyForPickup = 'READY_FOR_PICKUP';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';

  /// Urutan alur kerja, dipakai untuk menampilkan langkah pesanan.
  static const List<String> alur = <String>[
    pendingConfirmation,
    confirmed,
    washing,
    readyForPickup,
    completed,
  ];

  static String status(String? status) {
    switch (status) {
      case pendingConfirmation:
        return 'Menunggu Konfirmasi';
      case confirmed:
        return 'Dikonfirmasi';
      case washing:
        return 'Sedang Dicuci';
      case readyForPickup:
        return 'Siap Diambil';
      case completed:
        return 'Selesai';
      case cancelled:
        return 'Dibatalkan';
      default:
        return status == null || status.isEmpty ? '—' : status;
    }
  }

  static String statusPenjelasan(String? status) {
    switch (status) {
      case pendingConfirmation:
        return 'Pesanan sudah diterima dan menunggu dikonfirmasi admin.';
      case confirmed:
        return 'Pesanan dikonfirmasi dan akan segera diproses.';
      case washing:
        return 'Pakaian sedang dicuci.';
      case readyForPickup:
        return 'Pakaian sudah selesai dan siap diambil.';
      case completed:
        return 'Pesanan selesai.';
      case cancelled:
        return 'Pesanan dibatalkan.';
      default:
        return '';
    }
  }

  static String metodePembayaran(String? metode) {
    switch (metode) {
      case 'CASH':
        return 'Tunai (bayar di tempat)';
      case 'QRIS':
        return 'QRIS';
      case 'BANK_TRANSFER':
        return 'Transfer bank';
      case 'EWALLET':
        return 'Dompet digital';
      default:
        return 'Belum dipilih';
    }
  }

  static String metodePembayaranSingkat(String? metode) {
    switch (metode) {
      case 'CASH':
        return 'Tunai';
      case 'QRIS':
        return 'QRIS';
      case 'BANK_TRANSFER':
        return 'Transfer';
      case 'EWALLET':
        return 'E-wallet';
      default:
        return '—';
    }
  }

  static String statusPembayaran(String? status) {
    switch (status) {
      case 'PAID':
        return 'Lunas';
      case 'UNPAID':
        return 'Belum dibayar';
      default:
        return 'Belum tercatat';
    }
  }

  /// Metode non-tunai dicatat lunas oleh backend saat pesanan dibuat karena
  /// pembayarannya masih simulasi. Teks ini dipakai apa adanya di layar
  /// supaya pengguna tidak menyangka ada payment gateway sungguhan.
  static const String catatanSimulasi =
      'Metode non-tunai dicatat lunas otomatis oleh sistem. Pembayaran masih '
      'berupa simulasi di backend, belum melalui payment gateway.';

  static const String catatanTunai =
      'Bayar tunai saat mengambil pakaian. Admin menandai lunas setelah uang '
      'diterima.';

  /// Status yang boleh dibatalkan customer, mengikuti aturan backend
  /// (hanya sebelum pencucian dimulai).
  static bool bolehDibatalkanCustomer(String? status) =>
      status == pendingConfirmation || status == confirmed;

  static bool sudahFinal(String? status) =>
      status == completed || status == cancelled;

  /// Perpindahan status berikutnya yang diizinkan backend.
  static const Map<String, List<String>> transisi = <String, List<String>>{
    pendingConfirmation: <String>[confirmed, cancelled],
    confirmed: <String>[washing, cancelled],
    washing: <String>[readyForPickup, cancelled],
    readyForPickup: <String>[completed, cancelled],
    completed: <String>[],
    cancelled: <String>[],
  };

  static List<String> langkahBerikutnya(String? status) =>
      transisi[status] ?? const <String>[];
}
