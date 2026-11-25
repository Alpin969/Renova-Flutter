import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../core/network/api_exception.dart';
import '../../core/state/loadable.dart';
import '../../core/state/refresh_bus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_labels.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/order_row.dart';
import '../orders/order_detail_page.dart';

/// Ringkasan kerja admin.
///
/// Semua angka dihitung dari pesanan yang benar-benar dikirim server. Tidak
/// ada nilai contoh: bila data belum ada, angkanya nol dan layar mengatakan
/// apa adanya.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _mulai = false;
  Loadable<OrderList> _state = const Loading<OrderList>();
  RefreshBus? _bus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final bus = AppScope.of(context).refreshBus;
    if (_bus != bus) {
      _bus?.removeListener(_saatBerubah);
      _bus = bus..addListener(_saatBerubah);
    }

    if (_mulai) return;
    _mulai = true;
    _muat();
  }

  @override
  void dispose() {
    _bus?.removeListener(_saatBerubah);
    super.dispose();
  }

  void _saatBerubah() {
    if (mounted) _muat(tampilkanLoading: false);
  }

  Future<void> _muat({bool tampilkanLoading = true}) async {
    if (tampilkanLoading) {
      setState(() => _state = const Loading<OrderList>());
    }

    try {
      final hasil = await AppScope.of(context).orderRepository.listAll();
      if (!mounted) return;
      setState(() => _state = Ready<OrderList>(hasil));
    } catch (error) {
      if (!mounted) return;
      setState(() => _state = Failure<OrderList>(pesanKesalahan(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final nama = AppScope.sessionOf(context).user?.name ?? 'Admin';

    return RefreshIndicator(
      onRefresh: () => _muat(tampilkanLoading: false),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text('Dashboard', style: tema.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ringkasan pesanan yang perlu ditangani, ${nama.split(' ').first}.',
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          AsyncView<OrderList>(
            state: _state,
            onRetry: _muat,
            loadingText: 'Menghitung ringkasan pesanan…',
            builder: (context, hasil) => _IsiDashboard(
              daftar: hasil.items,
              terpotong: hasil.terpotong,
            ),
          ),
        ],
      ),
    );
  }
}

class _IsiDashboard extends StatelessWidget {
  const _IsiDashboard({required this.daftar, required this.terpotong});

  final List<Order> daftar;
  final bool terpotong;

  int _hitung(List<String> status) =>
      daftar.where((order) => status.contains(order.status)).length;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    final menunggu = _hitung(const [OrderLabels.pendingConfirmation]);
    final dikerjakan = _hitung(
      const [OrderLabels.confirmed, OrderLabels.washing],
    );
    final siapDiambil = _hitung(const [OrderLabels.readyForPickup]);
    final selesai = _hitung(const [OrderLabels.completed]);
    final dibatalkan = _hitung(const [OrderLabels.cancelled]);

    // Pendapatan hanya dari pesanan selesai yang punya harga akhir.
    final pendapatan = daftar
        .where((order) => order.status == OrderLabels.completed)
        .fold<double>(0, (total, order) => total + (order.totalPrice ?? 0));

    final perluTindakan = daftar
        .where(
          (order) =>
              order.status == OrderLabels.pendingConfirmation ||
              (order.status == OrderLabels.readyForPickup &&
                  order.paymentStatus != 'PAID'),
        )
        .take(5)
        .toList();

    if (daftar.isEmpty) {
      return const StateMessage(
        judul: 'Belum ada pesanan',
        pesan: 'Pesanan dari customer akan muncul di sini beserta statusnya.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Angka(
                label: 'Menunggu konfirmasi',
                nilai: '$menunggu',
                menonjol: menunggu > 0,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _Angka(label: 'Sedang dikerjakan', nilai: '$dikerjakan'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _Angka(label: 'Siap diambil', nilai: '$siapDiambil'),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _Angka(label: 'Selesai', nilai: '$selesai')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _Angka(
                label: 'Pendapatan pesanan selesai',
                nilai: Formats.rupiah(pendapatan),
                lebar: true,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _Angka(label: 'Dibatalkan', nilai: '$dibatalkan')),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Angka dihitung dari ${daftar.length} pesanan terakhir yang dikirim '
          'server. Pendapatan hanya menjumlahkan pesanan berstatus Selesai '
          'yang sudah punya harga akhir.',
          style: tema.textTheme.labelSmall,
        ),
        if (terpotong) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Daftar pesanan sangat banyak, sehingga ringkasan ini hanya '
            'menghitung sebagian. Buka tab Pesanan untuk melihat per status.',
            style: tema.textTheme.labelSmall?.copyWith(color: AppColors.accent),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        Text('Perlu ditangani', style: tema.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pesanan baru yang belum dikonfirmasi, dan pesanan siap diambil '
          'yang pembayarannya belum lunas.',
          style: tema.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        if (perluTindakan.isEmpty)
          const StateMessage(
            judul: 'Tidak ada yang menunggu',
            pesan: 'Semua pesanan sudah ditangani. Pesanan baru akan muncul '
                'di sini.',
          )
        else
          OrderListCard(
            children: [
              for (final order in perluTindakan)
                OrderRow(
                  order: order,
                  tampilkanCustomer: true,
                  onTap: () => OrderDetailPage.buka(
                    context,
                    order.id,
                    adminMode: true,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Satu angka ringkasan. Tidak memakai ikon dan tidak memakai warna latar
/// berbeda-beda: hanya label, angka, dan satu garis tepi.
class _Angka extends StatelessWidget {
  const _Angka({
    required this.label,
    required this.nilai,
    this.menonjol = false,
    this.lebar = false,
  });

  final String label;
  final String nilai;
  final bool menonjol;
  final bool lebar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: menonjol ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: tema.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            nilai,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (lebar ? tema.textTheme.titleSmall : tema.textTheme.headlineSmall)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: menonjol ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
