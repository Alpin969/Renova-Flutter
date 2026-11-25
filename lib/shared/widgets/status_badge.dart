import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/order_labels.dart';

/// Label status pesanan atau pembayaran.
///
/// Warna mengikuti maknanya, bukan dekorasi: coral untuk yang perlu
/// ditangani, cyan untuk yang berjalan normal atau selesai, abu untuk
/// keadaan yang netral atau sudah dibatalkan.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status})
      : pembayaran = false;

  const StatusBadge.pembayaran({super.key, required this.status})
      : pembayaran = true;

  final String status;
  final bool pembayaran;

  @override
  Widget build(BuildContext context) {
    final gaya = pembayaran ? _gayaPembayaran(status) : _gayaPesanan(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: gaya.latar,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        pembayaran
            ? OrderLabels.statusPembayaran(status)
            : OrderLabels.status(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: gaya.teks,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  _BadgeStyle _gayaPesanan(String status) {
    switch (status) {
      case OrderLabels.pendingConfirmation:
        return const _BadgeStyle(AppColors.accentSoft, AppColors.accent);
      case OrderLabels.confirmed:
      case OrderLabels.washing:
      case OrderLabels.readyForPickup:
        return const _BadgeStyle(AppColors.primarySoft, AppColors.primary);
      case OrderLabels.completed:
        return const _BadgeStyle(AppColors.neutralSoft, AppColors.textPrimary);
      case OrderLabels.cancelled:
        return const _BadgeStyle(AppColors.dangerSoft, AppColors.danger);
      default:
        return const _BadgeStyle(AppColors.neutralSoft, AppColors.textSecondary);
    }
  }

  _BadgeStyle _gayaPembayaran(String? status) {
    // Pembayaran adalah informasi uang: belum lunas harus terlihat jelas.
    switch (status) {
      case 'PAID':
        return const _BadgeStyle(AppColors.primarySoft, AppColors.primary);
      case 'UNPAID':
        return const _BadgeStyle(AppColors.accentSoft, AppColors.accent);
      default:
        return const _BadgeStyle(AppColors.neutralSoft, AppColors.textSecondary);
    }
  }
}

class _BadgeStyle {
  const _BadgeStyle(this.latar, this.teks);

  final Color latar;
  final Color teks;
}
