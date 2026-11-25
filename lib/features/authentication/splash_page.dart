import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/branding.dart';

/// Layar pembuka saat aplikasi dijalankan: logo, nama, dan status sesi.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RenovaLogo(size: 96),
              SizedBox(height: AppSpacing.lg),
              RenovaWordmark(),
              SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 96,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ditampilkan ketika token tersimpan belum bisa diperiksa karena server
/// tidak dapat dihubungi. Bukan alasan untuk keluar dari akun.
class SplashGagalPage extends StatelessWidget {
  const SplashGagalPage({
    super.key,
    required this.pesan,
    required this.onCobaLagi,
    required this.onMasukUlang,
  });

  final String pesan;
  final VoidCallback onCobaLagi;
  final VoidCallback onMasukUlang;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: RenovaLogo(size: 72)),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Tidak dapat memeriksa sesi', style: tema.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(pesan, style: tema.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: onCobaLagi,
                    child: const Text('Coba lagi'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: onMasukUlang,
                    child: const Text('Masuk dengan akun lain'),
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
