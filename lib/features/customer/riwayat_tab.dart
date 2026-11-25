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

/// Riwayat customer: pesanan yang sudah selesai atau dibatalkan.
class RiwayatTab extends StatefulWidget {
  const RiwayatTab({super.key});

  @override
  State<RiwayatTab> createState() => _RiwayatTabState();
}

class _RiwayatTabState extends State<RiwayatTab> {
  bool _mulai = false;
  Loadable<List<Order>> _state = const Loading<List<Order>>();
  RefreshBus? _bus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

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

  Future<void> _muat({bool tampilkanLoading = true}) async {
    if (tampilkanLoading) {
      setState(() => _state = const Loading<List<Order>>());
    }

    try {
      final daftar = await AppScope.of(context).orderRepository.listByStatuses(
        const <String>[OrderLabels.completed, OrderLabels.cancelled],
      );

      if (!mounted) return;
      setState(() => _state = Ready<List<Order>>(daftar));
    } catch (error) {
      if (!mounted) return;
      setState(() => _state = Failure<List<Order>>(pesanKesalahan(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

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
          Text('Riwayat', style: tema.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pesanan yang sudah selesai dan dibatalkan.',
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          AsyncView<List<Order>>(
            state: _state,
            onRetry: _muat,
            loadingText: 'Memuat riwayat…',
            builder: (context, daftar) {
              if (daftar.isEmpty) {
                return const StateMessage(
                  judul: 'Riwayat masih kosong',
                  pesan: 'Pesanan yang selesai atau dibatalkan akan tercatat '
                      'di sini.',
                );
              }

              return OrderListCard(
                children: [
                  for (final order in daftar)
                    OrderRow(
                      order: order,
                      onTap: () async {
                        await OrderDetailPage.buka(
                          context,
                          order.id,
                          adminMode: false,
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
    );
  }
}
