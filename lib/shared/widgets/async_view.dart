import 'package:flutter/material.dart';

import '../../core/state/loadable.dart';
import 'feedback.dart';

/// Menampilkan isi [Loadable] dengan tiga keadaan yang selalu jelas:
/// memuat, gagal (beserta tombol coba lagi), atau siap.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.state,
    required this.builder,
    required this.onRetry,
    this.loadingText = 'Memuat data…',
  });

  final Loadable<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final Future<void> Function() onRetry;
  final String loadingText;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      Loading<T>() => LoadingBlock(pesan: loadingText),
      Failure<T>(:final message) => StateMessage(
          judul: 'Data gagal dimuat',
          pesan: message,
          labelAksi: 'Coba lagi',
          onAksi: () => onRetry(),
          berbahaya: true,
        ),
      Ready<T>(:final data) => builder(context, data),
    };
  }
}

/// Tombol aksi kecil di dalam baris daftar atau header.
class SmallActionButton extends StatelessWidget {
  const SmallActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        child: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
      child: Text(label),
    );
  }
}
