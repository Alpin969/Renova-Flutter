import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/service_item.dart';
import '../../shared/widgets/feedback.dart';
import 'pesan_form_page.dart';

/// Isi beranda customer: sambutan, cara kerja singkat, dan daftar layanan
/// beserta tombol memesan. Data layanan selalu dari server.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onPesan});

  /// Membuka form pesanan untuk layanan tertentu.
  final void Function(ServiceItem layanan) onPesan;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<List<ServiceItem>> _layanan;

  @override
  void initState() {
    super.initState();
    _layanan = _muat();
  }

  Future<List<ServiceItem>> _muat() {
    final repo = AppScope.of(context).serviceRepository;
    return repo.list();
  }

  Future<void> _muatUlang() async {
    setState(() => _layanan = _muat());
    await _layanan;
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.sessionOf(context).user;
    final tema = Theme.of(context);
    final namaDepan = (user?.name ?? '').split(' ').first;

    return RefreshIndicator(
      onRefresh: _muatUlang,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${namaDepan.isEmpty ? 'Pelanggan' : namaDepan}',
                  style: tema.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pilih layanan laundry, isi estimasi berat, lalu kirim pesanan.',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _LangkahPesanan(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text('Layanan tersedia', style: tema.textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: _muatUlang,
                  child: const Text('Muat ulang'),
                ),
              ],
            ),
          ),
          FutureBuilder<List<ServiceItem>>(
            future: _layanan,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: LoadingBlock(pesan: 'Memuat layanan…'),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _LayananGagal(
                    pesan: pesanKesalahan(snapshot.error!),
                    onCobaLagi: _muatUlang,
                  ),
                );
              }

              final daftar = snapshot.data ?? const <ServiceItem>[];
              if (daftar.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _LayananKosong(),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _DaftarLayanan(daftar: daftar, onPesan: widget.onPesan),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DaftarLayanan extends StatelessWidget {
  const _DaftarLayanan({required this.daftar, required this.onPesan});

  final List<ServiceItem> daftar;
  final void Function(ServiceItem) onPesan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < daftar.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
            _LayananTile(
              layanan: daftar[i],
              onPesan: () => onPesan(daftar[i]),
              onDetail: () => LayananDetailPage.buka(context, daftar[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _LayananTile extends StatelessWidget {
  const _LayananTile({
    required this.layanan,
    required this.onPesan,
    required this.onDetail,
  });

  final ServiceItem layanan;
  final VoidCallback onPesan;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return InkWell(
      onTap: onDetail,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(layanan.name, style: tema.textTheme.titleSmall),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${Formats.rupiah(layanan.pricePerKg)}/kg',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Estimasi ${layanan.duration}',
              style: tema.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              layanan.deskripsiTampil,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDetail,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Lihat detail'),
                  ),
                ),
                FilledButton(
                  onPressed: onPesan,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: tema.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Pesan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiga langkah nyata pemesanan; bukan dekorasi, urutannya memang seperti
/// yang harus dilakukan pelanggan.
class _LangkahPesanan extends StatelessWidget {
  const _LangkahPesanan();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cara memesan',
            style: tema.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (nomor, teks) in const [
            ('1', 'Pilih layanan dan isi estimasi berat pakaian.'),
            ('2', 'Pilih metode pembayaran, lalu kirim pesanan.'),
            ('3', 'Pantau status di tab Pesanan sampai pakaian siap diambil.'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      nomor,
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(teks, style: tema.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LayananKosong extends StatelessWidget {
  const _LayananKosong();

  @override
  Widget build(BuildContext context) {
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
            'Belum ada layanan',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Admin belum menambahkan layanan laundry. Coba periksa kembali nanti.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LayananGagal extends StatelessWidget {
  const _LayananGagal({required this.pesan, required this.onCobaLagi});

  final String pesan;
  final Future<void> Function() onCobaLagi;

  @override
  Widget build(BuildContext context) {
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
            'Layanan gagal dimuat',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.danger,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(pesan, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => onCobaLagi(),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
