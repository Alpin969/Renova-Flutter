import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Bagian berjudul di dalam halaman detail.
///
/// Dipakai berulang agar susunan informasi pesanan konsisten: judul bagian
/// kecil, lalu baris label–nilai.
class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.judul,
    required this.children,
    this.aksi,
  });

  final String judul;
  final List<Widget> children;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  judul,
                  style: tema.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              ?aksi,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

/// Satu baris label dan nilai. Nilai bisa ditebalkan untuk angka penting.
///
/// Di layar sempit label dan nilai ditumpuk: label dengan lebar tetap membuat
/// nilai hanya sisa beberapa puluh piksel, dan email tanpa spasi akan pecah di
/// tengah kata ("mail.co" / "m").
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    this.nilai = '',
    this.tebal = false,
    this.nilaiWidget,
    this.warnaNilai,
  });

  final String label;
  final String nilai;
  final bool tebal;
  final Widget? nilaiWidget;
  final Color? warnaNilai;

  /// Di bawah lebar ini label dan nilai tidak lagi berdampingan.
  static const double _lebarMinimumBerderet = 340;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final gayaNilai = tebal
        ? tema.textTheme.titleSmall?.copyWith(
            color: warnaNilai ?? AppColors.textPrimary,
          )
        : tema.textTheme.bodyMedium?.copyWith(
            color: warnaNilai ?? AppColors.textPrimary,
          );

    final isiNilai = nilaiWidget ??
        Text(
          nilai,
          style: gayaNilai,
          textAlign: TextAlign.right,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: LayoutBuilder(
        builder: (context, batas) {
          if (batas.maxWidth < _lebarMinimumBerderet) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tema.textTheme.bodySmall),
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: gayaNilai,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: nilaiWidget ??
                        Text(nilai, style: gayaNilai),
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 132,
                child: Text(label, style: tema.textTheme.bodySmall),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: isiNilai),
            ],
          );
        },
      ),
    );
  }
}
