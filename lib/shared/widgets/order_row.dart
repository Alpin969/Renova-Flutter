import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_labels.dart';
import '../../data/models/order.dart';
import 'status_badge.dart';

/// Satu baris pesanan pada daftar.
///
/// Sengaja berbentuk baris (bukan card berwarna) supaya daftar panjang tetap
/// mudah dipindai: nomor, layanan, tanggal, lalu status di kanan.
class OrderRow extends StatelessWidget {
  const OrderRow({
    super.key,
    required this.order,
    required this.onTap,
    this.tampilkanCustomer = false,
  });

  final Order order;
  final VoidCallback onTap;

  /// Admin perlu tahu pesanan ini milik siapa.
  final bool tampilkanCustomer;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.namaLayanan,
                    style: tema.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              tampilkanCustomer
                  ? '${order.nomor} · ${order.namaCustomer}'
                  : order.nomor,
              style: tema.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  Formats.tanggalJam(order.createdAt),
                  style: tema.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  Formats.rupiah(order.totalPerkiraan),
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!order.totalSudahFinal)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'est.',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            if (order.paymentMethod != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '${OrderLabels.metodePembayaranSingkat(order.paymentMethod)} · '
                    '${OrderLabels.statusPembayaran(order.paymentStatus)}',
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: order.paymentStatus == 'UNPAID'
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pembungkus daftar dengan garis pemisah tipis antarbaris.
class OrderListCard extends StatelessWidget {
  const OrderListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isi = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        isi.add(const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg));
      }
      isi.add(children[i]);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: isi),
    );
  }
}
