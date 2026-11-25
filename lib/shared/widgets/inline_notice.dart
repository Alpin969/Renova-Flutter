import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Kotak keterangan singkat di dalam form: informasi atau kesalahan.
///
/// Dibedakan hanya lewat warna teks dan latar tipis, tanpa ikon besar,
/// supaya tidak bersaing dengan isi form.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.pesan,
    this.galat = false,
  });

  final String pesan;
  final bool galat;

  @override
  Widget build(BuildContext context) {
    final warna = galat ? AppColors.danger : AppColors.textSecondary;
    final latar = galat ? AppColors.dangerSoft : AppColors.surface;
    final garis = galat ? AppColors.danger.withValues(alpha: 0.25) : AppColors.border;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: garis),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (galat) ...[
            Icon(Icons.error_outline, size: 18, color: warna),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              pesan,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: warna,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
