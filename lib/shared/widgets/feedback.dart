import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Menampilkan pesan singkat di bagian bawah layar.
void tampilkanPesan(BuildContext context, String pesan, {bool galat = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: galat ? AppColors.danger : AppColors.textPrimary,
        duration: Duration(seconds: galat ? 5 : 3),
      ),
    );
}

/// Dialog konfirmasi untuk tindakan yang tidak bisa dibatalkan.
Future<bool> konfirmasi(
  BuildContext context, {
  required String judul,
  required String isi,
  String labelYa = 'Lanjutkan',
  String labelBatal = 'Batal',
  bool berbahaya = false,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              labelBatal,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: berbahaya
                ? FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size(0, 44),
                  )
                : FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(labelYa),
          ),
        ],
      );
    },
  );

  return hasil ?? false;
}

/// Keadaan kosong atau gagal: menyebut sebabnya dan langkah berikutnya,
/// bukan sekadar "tidak ada data".
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.judul,
    required this.pesan,
    this.labelAksi,
    this.onAksi,
    this.berbahaya = false,
  });

  final String judul;
  final String pesan;
  final String? labelAksi;
  final VoidCallback? onAksi;
  final bool berbahaya;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: tema.textTheme.titleSmall?.copyWith(
              color: berbahaya ? AppColors.danger : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(pesan, style: tema.textTheme.bodyMedium),
          if (labelAksi != null && onAksi != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onAksi,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: Text(labelAksi!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Penanda proses memuat. Menyebut apa yang sedang dimuat, bukan spinner
/// tanpa keterangan.
class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key, this.pesan = 'Memuat data…'});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(pesan, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Spinner kecil di dalam tombol.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, this.warna = Colors.white});

  final Color warna;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: warna),
    );
  }
}
