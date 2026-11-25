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

/// Semua pesanan, dikelompokkan per status.
///
/// Penyaringan dilakukan server lewat `?status=`; aplikasi hanya mengirim
/// nilai status yang memang dikenal backend.
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  static const List<(String?, String)> _filter = <(String?, String)>[
    (null, 'Semua'),
    (OrderLabels.pendingConfirmation, 'Menunggu'),
    (OrderLabels.confirmed, 'Dikonfirmasi'),
    (OrderLabels.washing, 'Dicuci'),
    (OrderLabels.readyForPickup, 'Siap diambil'),
  ];

  int _indeks = 0;
  bool _mulai = false;
  Loadable<List<Order>> _state = const Loading<List<Order>>();
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
      setState(() => _state = const Loading<List<Order>>());
    }

    try {
      final daftar = await AppScope.of(context)
          .orderRepository
          .list(status: _filter[_indeks].$1);

      if (!mounted) return;
      setState(() => _state = Ready<List<Order>>(daftar.items));
    } catch (error) {
      if (!mounted) return;
      setState(() => _state = Failure<List<Order>>(pesanKesalahan(error)));
    }
  }

  void _gantiFilter(int nilai) {
    if (_indeks == nilai) return;
    setState(() => _indeks = nilai);
    _muat();
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
                'Pesanan masuk dari semua customer.',
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (var i = 0; i < _filter.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(_filter[i].$2),
                    selected: _indeks == i,
                    showCheckmark: false,
                    onSelected: (_) => _gantiFilter(i),
                    labelStyle: tema.textTheme.labelMedium?.copyWith(
                      color: _indeks == i
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          _indeks == i ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
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
                      return StateMessage(
                        judul: 'Tidak ada pesanan',
                        pesan: _indeks == 0
                            ? 'Belum ada pesanan yang masuk.'
                            : 'Tidak ada pesanan dengan status '
                                '"${_filter[_indeks].$2}".',
                      );
                    }

                    return OrderListCard(
                      children: [
                        for (final order in daftar)
                          OrderRow(
                            order: order,
                            tampilkanCustomer: true,
                            onTap: () async {
                              await OrderDetailPage.buka(
                                context,
                                order.id,
                                adminMode: true,
                              );
                              if (!context.mounted) return;
                              await _muat(tampilkanLoading: false);
                            },
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
