import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../core/network/api_exception.dart';
import '../../core/state/loadable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_labels.dart';
import '../../core/utils/validators.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/detail_section.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/inline_notice.dart';
import '../../shared/widgets/order_photo.dart';
import '../../shared/widgets/status_badge.dart';

/// Detail satu pesanan, dipakai customer maupun admin.
///
/// Tindakan yang tampil mengikuti aturan backend: customer hanya bisa
/// membatalkan pada dua status awal, sedangkan admin bisa memproses status,
/// mengisi berat asli, mengonfirmasi pembayaran tunai, dan membatalkan.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.adminMode,
  });

  final int orderId;
  final bool adminMode;

  static Future<void> buka(
    BuildContext context,
    int orderId, {
    required bool adminMode,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailPage(
          orderId: orderId,
          adminMode: adminMode,
        ),
      ),
    );
  }

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _mulai = false;
  bool _sedangAksi = false;
  Loadable<Order> _state = const Loading<Order>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mulai) return;
    _mulai = true;
    _muat();
  }

  Future<void> _muat({bool tampilkanLoading = true}) async {
    if (tampilkanLoading) {
      setState(() => _state = const Loading<Order>());
    }

    try {
      final order = await AppScope.of(context)
          .orderRepository
          .detail(widget.orderId);

      if (!mounted) return;
      setState(() => _state = Ready<Order>(order));
    } catch (error) {
      if (!mounted) return;
      setState(() => _state = Failure<Order>(pesanKesalahan(error)));
    }
  }

  /// Menjalankan satu tindakan ke server, lalu memakai data yang dikirim
  /// balik server sebagai isi layar — bukan menebak hasilnya di aplikasi.
  Future<void> _jalankan(
    Future<Order> Function() aksi,
    String pesanSukses,
  ) async {
    setState(() => _sedangAksi = true);

    try {
      final terbaru = await aksi();
      if (!mounted) return;

      setState(() {
        _state = Ready<Order>(terbaru);
        _sedangAksi = false;
      });

      AppScope.of(context).refreshBus.tandaBerubah();
      tampilkanPesan(context, pesanSukses);
    } catch (error) {
      if (!mounted) return;
      setState(() => _sedangAksi = false);
      tampilkanPesan(context, pesanKesalahan(error), galat: true);
    }
  }

  Future<void> _batalkan(Order order) async {
    final setuju = await konfirmasi(
      context,
      judul: 'Batalkan pesanan?',
      isi: widget.adminMode
          ? 'Pesanan ${order.nomor} akan dibatalkan. Tindakan ini tidak bisa '
              'dibatalkan lagi.'
          : 'Pesanan ${order.nomor} akan dibatalkan. Setelah dibatalkan, '
              'pesanan tidak bisa diproses lagi.',
      labelYa: 'Batalkan pesanan',
      labelBatal: 'Tidak',
      berbahaya: true,
    );

    if (!setuju || !mounted) return;

    await _jalankan(
      () => AppScope.of(context).orderRepository.cancel(order.id),
      'Pesanan ${order.nomor} dibatalkan.',
    );
  }

  Future<void> _ubahStatus(Order order, String statusBaru) async {
    final setuju = await konfirmasi(
      context,
      judul: 'Ubah status pesanan?',
      isi: 'Status pesanan ${order.nomor} akan diubah menjadi '
          '"${OrderLabels.status(statusBaru)}".',
      labelYa: 'Ubah status',
    );

    if (!setuju || !mounted) return;

    await _jalankan(
      () => AppScope.of(context)
          .orderRepository
          .updateStatus(order.id, statusBaru),
      'Status pesanan diperbarui menjadi ${OrderLabels.status(statusBaru)}.',
    );
  }

  Future<void> _isiBerat(Order order) async {
    final controller = TextEditingController(
      text: order.actualWeight == null
          ? ''
          : Formats.isianAngka(order.actualWeight),
    );
    final formKey = GlobalKey<FormState>();

    final berat = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Isi berat asli'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Berat asli (kg)',
                  controller: controller,
                  hint: 'Contoh: 2,75',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.berat,
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Harga per kg ${Formats.rupiah(order.pricePerKg)}. '
                  'Total akhir dihitung server setelah berat disimpan.',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final nilai = Validators.keAngkaBerat(controller.text);
                Navigator.of(dialogContext).pop(nilai);
              },
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (berat == null || !mounted) return;

    await _jalankan(
      () => AppScope.of(context).orderRepository.setActualWeight(order.id, berat),
      'Berat asli dan harga akhir pesanan disimpan.',
    );
  }

  Future<void> _konfirmasiBayar(Order order) async {
    final setuju = await konfirmasi(
      context,
      judul: 'Konfirmasi pembayaran?',
      isi: 'Tandai pembayaran ${order.nomor} sudah diterima. Tindakan ini '
          'mencatat pembayaran lunas di server.',
      labelYa: 'Sudah diterima',
    );

    if (!setuju || !mounted) return;

    await _jalankan(
      () => AppScope.of(context).orderRepository.confirmPayment(order.id),
      'Pembayaran pesanan dikonfirmasi lunas.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.adminMode ? 'Detail pesanan' : 'Pesanan saya'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: RefreshIndicator(
              onRefresh: () => _muat(tampilkanLoading: false),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AsyncView<Order>(
                    state: _state,
                    onRetry: _muat,
                    loadingText: 'Memuat pesanan…',
                    builder: (context, order) => _IsiDetail(
                      order: order,
                      adminMode: widget.adminMode,
                      sedangAksi: _sedangAksi,
                      onBatalkan: () => _batalkan(order),
                      onUbahStatus: (status) => _ubahStatus(order, status),
                      onIsiBerat: () => _isiBerat(order),
                      onKonfirmasiBayar: () => _konfirmasiBayar(order),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IsiDetail extends StatelessWidget {
  const _IsiDetail({
    required this.order,
    required this.adminMode,
    required this.sedangAksi,
    required this.onBatalkan,
    required this.onUbahStatus,
    required this.onIsiBerat,
    required this.onKonfirmasiBayar,
  });

  final Order order;
  final bool adminMode;
  final bool sedangAksi;
  final VoidCallback onBatalkan;
  final ValueChanged<String> onUbahStatus;
  final VoidCallback onIsiBerat;
  final VoidCallback onKonfirmasiBayar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.nomor, style: tema.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Formats.tanggalJam(order.createdAt),
                    style: tema.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            StatusBadge(status: order.status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          OrderLabels.statusPenjelasan(order.status),
          style: tema.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (adminMode)
          DetailSection(
            judul: 'Customer',
            children: [
              DetailRow(label: 'Nama', nilai: order.namaCustomer),
              DetailRow(label: 'Email', nilai: order.customerEmail ?? '—'),
            ],
          ),
        if (adminMode) const SizedBox(height: AppSpacing.lg),

        DetailSection(
          judul: 'Rincian pesanan',
          children: [
            DetailRow(label: 'Layanan', nilai: order.namaLayanan),
            if (order.serviceDuration != null)
              DetailRow(label: 'Estimasi pengerjaan', nilai: order.serviceDuration!),
            DetailRow(label: 'Estimasi berat', nilai: Formats.berat(order.estimatedWeight)),
            DetailRow(
              label: 'Berat asli',
              nilai: order.actualWeight == null
                  ? 'Belum ditimbang'
                  : Formats.berat(order.actualWeight),
              tebal: order.actualWeight != null,
            ),
            DetailRow(label: 'Harga per kg', nilai: Formats.rupiah(order.pricePerKg)),
            const Divider(height: AppSpacing.lg),
            DetailRow(
              label: order.totalSudahFinal ? 'Total akhir' : 'Perkiraan total',
              nilai: Formats.rupiah(order.totalPerkiraan),
              tebal: true,
              warnaNilai: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        DetailSection(
          judul: 'Pembayaran',
          children: [
            DetailRow(
              label: 'Metode',
              nilai: OrderLabels.metodePembayaran(order.paymentMethod),
            ),
            DetailRow(
              label: 'Status',
              nilaiWidget: Align(
                alignment: Alignment.centerRight,
                child: StatusBadge.pembayaran(status: order.paymentStatus ?? ''),
              ),
            ),
            if (order.paidAt != null)
              DetailRow(label: 'Dibayar', nilai: Formats.tanggalJam(order.paidAt)),
            const SizedBox(height: AppSpacing.sm),
            InlineNotice(
              pesan: order.paymentMethod == 'CASH'
                  ? OrderLabels.catatanTunai
                  : OrderLabels.catatanSimulasi,
            ),
          ],
        ),

        if (order.photoUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          DetailSection(
            judul: 'Foto pakaian',
            children: [OrderPhoto(url: order.photoUrl!)],
          ),
        ],

        if (_adaTindakan) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            adminMode ? 'Tindakan admin' : 'Tindakan',
            style: tema.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._tombolAksi(context),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  bool get _adaTindakan {
    if (sedangAksi) return true;
    if (order.sudahFinal) return false;

    if (!adminMode) {
      return OrderLabels.bolehDibatalkanCustomer(order.status);
    }

    return true;
  }

  List<Widget> _tombolAksi(BuildContext context) {
    if (sedangAksi) {
      return const <Widget>[LoadingBlock(pesan: 'Memproses…')];
    }

    final tombol = <Widget>[];

    if (adminMode) {
      // Berat asli bisa diisi selama pesanan belum final; harga akhir
      // dihitung server dari nilai ini.
      tombol.add(
        OutlinedButton(
          onPressed: onIsiBerat,
          child: Text(
            order.sudahAdaBeratAsli ? 'Ubah berat asli' : 'Isi berat asli',
          ),
        ),
      );

      if (order.paymentMethod == 'CASH' && order.paymentStatus != 'PAID') {
        tombol.add(const SizedBox(height: AppSpacing.sm));
        tombol.add(
          OutlinedButton(
            onPressed: onKonfirmasiBayar,
            child: const Text('Konfirmasi pembayaran tunai'),
          ),
        );
      }

      final berikutnya = OrderLabels.langkahBerikutnya(order.status)
          .where((status) => status != OrderLabels.cancelled)
          .toList();

      for (final status in berikutnya) {
        tombol.add(const SizedBox(height: AppSpacing.sm));
        tombol.add(
          FilledButton(
            onPressed: () => onUbahStatus(status),
            child: Text('Tandai ${OrderLabels.status(status)}'),
          ),
        );
      }

      if (berikutnya.contains(OrderLabels.completed) &&
          (!order.sudahAdaBeratAsli || order.paymentStatus != 'PAID')) {
        tombol.add(const SizedBox(height: AppSpacing.sm));
        tombol.add(
          InlineNotice(
            pesan: 'Pesanan hanya bisa diselesaikan setelah berat asli diisi '
                'dan pembayaran lunas. Server akan menolak bila syarat belum '
                'terpenuhi.',
          ),
        );
      }
    }

    tombol.add(const SizedBox(height: AppSpacing.md));
    tombol.add(
      OutlinedButton(
        onPressed: onBatalkan,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.border),
        ),
        child: const Text('Batalkan pesanan'),
      ),
    );

    return tombol;
  }
}
