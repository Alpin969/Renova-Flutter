import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Logo RENOVA untuk splash, halaman autentikasi, dan profil.
///
/// Bentuk logo dipertahankan apa adanya: hanya gambar yang disediakan yang
/// dipakai, tanpa membuat versi baru atau menambahkan efek.
class RenovaLogo extends StatelessWidget {
  const RenovaLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/logos/logo_renova.png',
        fit: BoxFit.contain,
        semanticLabel: 'Logo RENOVA',
        errorBuilder: (context, error, stack) => Container(
          // Cadangan bila aset tidak ikut terbundel: huruf R besar, bukan
          // ikon generik.
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'R',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Nama aplikasi dalam gaya yang sama dengan logo.
class RenovaWordmark extends StatelessWidget {
  const RenovaWordmark({super.key, this.tampilkanTagline = true});

  final bool tampilkanTagline;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'RENOVA',
          style: tema.textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            letterSpacing: 6,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (tampilkanTagline) ...[
          const SizedBox(height: 2),
          Text(
            'LAUNDRY',
            style: tema.textTheme.labelSmall?.copyWith(
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Header halaman dengan judul dan penjelasan singkat.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.judul,
    this.keterangan,
    this.aksi,
  });

  final String judul;
  final String? keterangan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: tema.textTheme.headlineSmall),
                if (keterangan != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(keterangan!, style: tema.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (aksi != null) ...[
            const SizedBox(width: AppSpacing.md),
            aksi!,
          ],
        ],
      ),
    );
  }
}
