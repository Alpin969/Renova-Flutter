import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../core/network/api_exception.dart';
import '../../core/state/loadable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/service_item.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/inline_notice.dart';

/// Manajemen layanan: daftar, tambah, ubah, hapus.
///
/// Penolakan server (mis. layanan masih dipakai pesanan) ditampilkan apa
/// adanya; daftar hanya berubah setelah server benar-benar menerima.
class AdminServicesTab extends StatefulWidget {
  const AdminServicesTab({super.key});

  @override
  State<AdminServicesTab> createState() => _AdminServicesTabState();
}

class _AdminServicesTabState extends State<AdminServicesTab> {
  bool _mulai = false;
  Loadable<List<ServiceItem>> _state = const Loading<List<ServiceItem>>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mulai) return;
    _mulai = true;
    _muat();
  }

  Future<void> _muat({bool tampilkanLoading = true}) async {
    if (tampilkanLoading) {
      setState(() => _state = const Loading<List<ServiceItem>>());
    }

    try {
      final daftar = await AppScope.of(context).serviceRepository.list();
      if (!mounted) return;
      setState(() => _state = Ready<List<ServiceItem>>(daftar));
    } catch (error) {
      if (!mounted) return;
      setState(() => _state = Failure<List<ServiceItem>>(pesanKesalahan(error)));
    }
  }

  Future<void> _tambah() async {
    final berhasil = await _bukaForm(context);
    if (!mounted || berhasil != true) return;
    await _muat(tampilkanLoading: false);
  }

  Future<void> _ubah(ServiceItem layanan) async {
    final berhasil = await _bukaForm(context, layanan: layanan);
    if (!mounted || berhasil != true) return;
    await _muat(tampilkanLoading: false);
  }

  Future<void> _hapus(ServiceItem layanan) async {
    final setuju = await konfirmasi(
      context,
      judul: 'Hapus layanan?',
      isi: 'Layanan "${layanan.name}" akan dihapus. Layanan yang sudah dipakai '
          'pesanan tidak bisa dihapus oleh server.',
      labelYa: 'Hapus',
      berbahaya: true,
    );

    if (!setuju || !mounted) return;

    try {
      await AppScope.of(context).serviceRepository.remove(layanan.id);
      if (!mounted) return;
      tampilkanPesan(context, 'Layanan "${layanan.name}" dihapus.');
      await _muat(tampilkanLoading: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      // Penolakan backend ditampilkan utuh, termasuk alasan layanan tidak
      // bisa dihapus.
      tampilkanPesan(context, error.message, galat: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Layanan', style: tema.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Layanan dan harga yang dilihat customer.',
                      style: tema.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton(
                onPressed: _tambah,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: tema.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Tambah'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _muat(tampilkanLoading: false),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                AsyncView<List<ServiceItem>>(
                  state: _state,
                  onRetry: _muat,
                  loadingText: 'Memuat layanan…',
                  builder: (context, daftar) {
                    if (daftar.isEmpty) {
                      return const StateMessage(
                        judul: 'Belum ada layanan',
                        pesan: 'Tambahkan layanan pertama agar customer bisa '
                            'memesan.',
                      );
                    }

                    return Column(
                      children: [
                        for (final layanan in daftar)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _KartuLayanan(
                              layanan: layanan,
                              onUbah: () => _ubah(layanan),
                              onHapus: () => _hapus(layanan),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KartuLayanan extends StatelessWidget {
  const _KartuLayanan({
    required this.layanan,
    required this.onUbah,
    required this.onHapus,
  });

  final ServiceItem layanan;
  final VoidCallback onUbah;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(layanan.name, style: tema.textTheme.titleSmall),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${Formats.rupiah(layanan.pricePerKg)}/kg',
                style: tema.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Estimasi ${layanan.duration}', style: tema.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            layanan.deskripsiTampil,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onUbah,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: const Text('Ubah'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: onHapus,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Hapus'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Form tambah/ubah layanan. Mengembalikan `true` bila server menerima.
Future<bool?> _bukaForm(BuildContext context, {ServiceItem? layanan}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormLayanan(layanan: layanan),
  );
}

class _FormLayanan extends StatefulWidget {
  const _FormLayanan({this.layanan});

  final ServiceItem? layanan;

  @override
  State<_FormLayanan> createState() => _FormLayananState();
}

class _FormLayananState extends State<_FormLayanan> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _harga;
  late final TextEditingController _durasi;
  late final TextEditingController _deskripsi;
  bool _mengirim = false;
  String? _pesanGalat;

  bool get _mengubah => widget.layanan != null;

  @override
  void initState() {
    super.initState();
    final layanan = widget.layanan;
    _nama = TextEditingController(text: layanan?.name ?? '');
    _harga = TextEditingController(
      text: layanan == null ? '' : Formats.isianAngka(layanan.pricePerKg),
    );
    _durasi = TextEditingController(text: layanan?.duration ?? '');
    _deskripsi = TextEditingController(text: layanan?.description ?? '');
  }

  @override
  void dispose() {
    _nama.dispose();
    _harga.dispose();
    _durasi.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final harga = Validators.keAngkaHarga(_harga.text);
    if (harga == null) return;

    setState(() {
      _mengirim = true;
      _pesanGalat = null;
    });

    final repo = AppScope.of(context).serviceRepository;

    try {
      if (_mengubah) {
        await repo.update(
          widget.layanan!.id,
          name: _nama.text,
          duration: _durasi.text,
          pricePerKg: harga,
          description: _deskripsi.text,
        );
      } else {
        await repo.create(
          name: _nama.text,
          duration: _durasi.text,
          pricePerKg: harga,
          description: _deskripsi.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      tampilkanPesan(
        context,
        _mengubah ? 'Layanan diperbarui.' : 'Layanan ditambahkan.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mengirim = false;
        _pesanGalat = pesanKesalahan(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _mengubah ? 'Ubah layanan' : 'Tambah layanan',
                style: tema.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Nama layanan',
                controller: _nama,
                hint: 'Contoh: Cuci Kering',
                validator: Validators.namaLayanan,
                enabled: !_mengirim,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Harga per kg (Rp)',
                controller: _harga,
                hint: 'Contoh: 7000',
                keyboardType: TextInputType.number,
                validator: Validators.harga,
                enabled: !_mengirim,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Durasi',
                controller: _durasi,
                hint: 'Contoh: 2 hari',
                validator: Validators.durasi,
                enabled: !_mengirim,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Deskripsi (opsional)',
                controller: _deskripsi,
                hint: 'Penjelasan singkat layanan',
                maxLines: 3,
                validator: Validators.deskripsiLayanan,
                enabled: !_mengirim,
              ),

              if (_pesanGalat != null) ...[
                const SizedBox(height: AppSpacing.lg),
                InlineNotice(pesan: _pesanGalat!, galat: true),
              ],

              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _mengirim ? null : _simpan,
                child: _mengirim
                    ? const ButtonSpinner()
                    : Text(_mengubah ? 'Simpan perubahan' : 'Tambah layanan'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _mengirim ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
