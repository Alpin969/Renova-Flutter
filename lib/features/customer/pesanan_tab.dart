import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../core/network/api_exception.dart';
import '../../core/state/loadable.dart';
import '../../core/state/refresh_bus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/order_labels.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/order_row.dart';
import '../orders/order_detail_page.dart';

/// Daftar pesanan customer, dipisah menurut keadaan: yang masih berjalan,
/// yang sudah selesai, dan yang dibatalkan.
class PesananTab extends StatefulWidget {
  const PesananTab({super.key});

  @override
  State<PesananTab> createState() => _PesananTabState();
}

class _PesananTabState extends State<PesananTab> {
  static const List<String> _aktif = <String>[
    OrderLabels.pendingConfirmation,
    OrderLabels.confirmed,
    OrderLabels.washing,
    OrderLabels.readyForPickup,
  ];

  int _filter = 0;
  bool _mulai = false;
  Loadable<List<Order>> _state = const Loading<List<Order>>();
  RefreshBus? _bus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Mendengarkan perubahan data pesanan dari layar lain (mis. setelah
    // membatalkan pesanan di halaman detail).
    final bus = AppScope.of(context).refreshBus;
    if (_bus != bus) {
      _bus?.removeListener(_saatDataBerubah);
      _bus = bus..addListener(_saatDataBerubah);
    }

    if (_mulai) return;
    _mulai = true;
    _muat();
  }

  @override
  void dispose() {
    _bus?.removeListener(_saatDataBerubah);
    super.dispose();
  }

  void _saatDataBerubah() {
    if (mounted) _muat(tampilkanLoading: false);
  }

  List<String> get _statusTerpilih {
    switch (_filter) {
      case 1:
        return const <String>[OrderLabels.completed];
      case 2:
        return const <String>[OrderLabels.cancelled];
      default:
        return _aktif;
    }
  }

  Future<void> _muat({bool tampilkanLoading = true}) async {
    if (tampilkanLoading) {
      setState(() => _state = const Loading<List<Order>>());
    }

    try {
      final daftar = await AppScope.of(context)
          .orderRepository
          .listByStatuses(_statusTerpilih);

      if (!mounted) return;
      setState(() => _state = Ready<List<Order>>(daftar));
    } catch (error) {
      if (!mounted) return;
      setState(() => _state = Failure<List<Order>>(pesanKesalahan(error)));
    }
  }

  void _gantiFilter(int nilai) {
    if (_filter == nilai) return;
    setState(() => _filter = nilai);
    _muat();
  }

  Future<void> _bukaDetail(Order order) async {
    await OrderDetailPage.buka(context, order.id, adminMode: false);
    if (!mounted) return;
    await _muat(tampilkanLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pesanan', style: tema.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pantau status pengerjaan pesanan Anda di sini.',
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _FilterBar(
          nilai: _filter,
          onPilih: _gantiFilter,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _muat(tampilkanLoading: false),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                AsyncView<List<Order>>(
                  state: _state,
                  onRetry: _muat,
                  loadingText: 'Memuat pesanan…',
                  builder: (context, daftar) {
                    if (daftar.isEmpty) {
                      return _KosongPesanan(filter: _filter);
                    }

                    return OrderListCard(
                      children: [
                        for (final order in daftar)
                          OrderRow(
                            order: order,
                            onTap: () => _bukaDetail(order),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.nilai, required this.onPilih});

  final int nilai;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    const label = <String>['Sedang berjalan', 'Selesai', 'Dibatalkan'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < label.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(label[i]),
                selected: nilai == i,
                showCheckmark: false,
                onSelected: (_) => onPilih(i),
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: nilai == i
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          nilai == i ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KosongPesanan extends StatelessWidget {
  const _KosongPesanan({required this.filter});

  final int filter;

  @override
  Widget build(BuildContext context) {
    final (judul, pesan) = switch (filter) {
      1 => (
          'Belum ada pesanan selesai',
          'Pesanan yang sudah selesai akan muncul di sini.',
        ),
      2 => (
          'Tidak ada pesanan dibatalkan',
          'Pesanan yang dibatalkan akan muncul di sini.',
        ),
      _ => (
          'Belum ada pesanan berjalan',
          'Buat pesanan dari beranda. Pesanan yang sedang diproses akan muncul di sini.',
        ),
    };

    return StateMessage(judul: judul, pesan: pesan);
  }
}
