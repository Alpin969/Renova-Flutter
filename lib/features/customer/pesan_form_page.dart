import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import '../../core/di/app_scope.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_labels.dart';
import '../../core/utils/validators.dart';
import '../../data/models/order.dart';
import '../../data/models/service_item.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/inline_notice.dart';
import '../../shared/widgets/order_photo.dart';

/// Satu halaman pemesanan untuk satu layanan.
///
/// Backend membuat satu pesanan per layanan, jadi form ini memang untuk satu
/// layanan — tidak ada keranjang yang menyimpan banyak layanan sekaligus.
class PesanFormPage extends StatefulWidget {
  const PesanFormPage({super.key, required this.layanan});

  final ServiceItem layanan;

  static Future<bool?> buka(BuildContext context, ServiceItem layanan) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PesanFormPage(layanan: layanan),
      ),
    );
  }

  @override
  State<PesanFormPage> createState() => _PesanFormPageState();
}

class _PesanFormPageState extends State<PesanFormPage> {
  static const List<String> _metode = <String>[
    'CASH',
    'QRIS',
    'BANK_TRANSFER',
    'EWALLET',
  ];

  final _formKey = GlobalKey<FormState>();
  final _berat = TextEditingController();
  String _metodePilih = 'CASH';
  bool _mengirim = false;
  String? _pesanGalat;

  /// Pesanan sudah terbentuk di server, foto sedang diunggah.
  Order? _pesanan;
  bool _fotoSedangDiunggah = false;

  @override
  void dispose() {
    _berat.dispose();
    super.dispose();
  }

  double? get _beratAngka => double.tryParse(
        _berat.text.trim().replaceAll(',', '.'),
      );

  double get _perkiraanTotal => (_beratAngka ?? 0) * widget.layanan.pricePerKg;

  Future<void> _kirim() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final berat = _beratAngka;
    if (berat == null) return;

    setState(() {
      _mengirim = true;
      _pesanGalat = null;
    });

    final deps = AppScope.of(context);

    try {
      final order = await deps.orderRepository.create(
        serviceId: widget.layanan.id,
        estimatedWeight: berat,
        paymentMethod: _metodePilih,
      );

      if (!mounted) return;
      setState(() {
        _pesanan = order;
        _mengirim = false;
      });

      deps.refreshBus.tandaBerubah();
      tampilkanPesan(
        context,
        'Pesanan ${order.nomor} berhasil dibuat.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _pesanGalat = error.message;
        _mengirim = false;
      });
    }
  }

  Future<void> _pilihFoto(ImageSource sumber) async {
    final order = _pesanan;
    if (order == null) return;

    final deps = AppScope.of(context);

    try {
      final foto = await deps.photoPicker.ambil(sumber);
      if (foto == null || !mounted) return;

      setState(() => _fotoSedangDiunggah = true);

      final terbaru = await deps.orderRepository.uploadPhoto(
        order.id,
        bytes: foto.bytes,
        filename: foto.filename,
        contentType: foto.contentType,
      );

      if (!mounted) return;
      setState(() {
        _pesanan = terbaru;
        _fotoSedangDiunggah = false;
      });
      deps.refreshBus.tandaBerubah();
      tampilkanPesan(context, 'Foto pesanan berhasil diunggah.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _fotoSedangDiunggah = false);
      tampilkanPesan(context, pesanKesalahan(error), galat: true);
    }
  }

  Future<void> _hapusFoto() async {
    final order = _pesanan;
    if (order == null) return;

    final setuju = await konfirmasi(
      context,
      judul: 'Hapus foto pesanan?',
      isi: 'Foto yang sudah diunggah akan dihapus dari server.',
      labelYa: 'Hapus foto',
      berbahaya: true,
    );
    if (!setuju || !mounted) return;

    final deps = AppScope.of(context);
    setState(() => _fotoSedangDiunggah = true);

    try {
      final terbaru = await deps.orderRepository.deletePhoto(order.id);
      if (!mounted) return;
      setState(() {
        _pesanan = terbaru;
        _fotoSedangDiunggah = false;
      });
      deps.refreshBus.tandaBerubah();
      tampilkanPesan(context, 'Foto pesanan dihapus.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _fotoSedangDiunggah = false);
      tampilkanPesan(context, pesanKesalahan(error), galat: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pesanan = _pesanan;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(pesanan != null),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(pesanan == null ? 'Buat pesanan' : 'Pesanan dibuat'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: pesanan == null ? _buildForm() : _buildSetelahDibuat(pesanan),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: pesanan == null
              ? FilledButton(
                  onPressed: _mengirim ? null : _kirim,
                  child: _mengirim
                      ? const ButtonSpinner()
                      : const Text('Kirim pesanan'),
                )
              : FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Lihat pesanan saya'),
                ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final tema = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _RingkasanLayanan(layanan: widget.layanan),
          const SizedBox(height: AppSpacing.xl),

          AppTextField(
            label: 'Estimasi berat (kg)',
            controller: _berat,
            hint: 'Contoh: 2,5',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            validator: Validators.berat,
            onChanged: (_) => setState(() {}),
            enabled: !_mengirim,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Berat akhir ditentukan admin saat pakaian ditimbang. '
            'Total di bawah masih perkiraan.',
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Metode pembayaran', style: tema.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _PilihanMetode(
            nilai: _metodePilih,
            opsi: _metode,
            onPilih: (nilai) => setState(() => _metodePilih = nilai),
            aktif: !_mengirim,
          ),
          const SizedBox(height: AppSpacing.md),
          InlineNotice(
            pesan: _metodePilih == 'CASH'
                ? OrderLabels.catatanTunai
                : OrderLabels.catatanSimulasi,
          ),
          const SizedBox(height: AppSpacing.xl),

          _RingkasanBiaya(
            hargaPerKg: widget.layanan.pricePerKg,
            berat: _beratAngka,
            total: _perkiraanTotal,
          ),

          if (_pesanGalat != null) ...[
            const SizedBox(height: AppSpacing.lg),
            InlineNotice(pesan: _pesanGalat!, galat: true),
          ],
        ],
      ),
    );
  }

  Widget _buildSetelahDibuat(Order pesanan) {
    final tema = Theme.of(context);
    final adaFoto = pesanan.photoUrl != null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        InlineNotice(
          pesan: 'Pesanan ${pesanan.nomor} sudah tercatat di server. '
              'Anda bisa menambahkan satu foto pakaian, atau langsung melihat '
              'pesanannya.',
        ),
        const SizedBox(height: AppSpacing.xl),

        Text('Foto pakaian (opsional)', style: tema.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Maksimal satu foto, format JPG, PNG, atau WebP, ukuran sampai 2 MB.',
          style: tema.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        if (_fotoSedangDiunggah)
          const LoadingBlock(pesan: 'Mengunggah foto ke server…')
        else if (adaFoto) ...[
          OrderPhoto(url: pesanan.photoUrl!, tinggi: 200),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pilihFoto(ImageSource.gallery),
                  child: const Text('Ganti foto'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: _hapusFoto,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Text('Hapus foto'),
                ),
              ),
            ],
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pilihFoto(ImageSource.gallery),
                  child: const Text('Pilih dari galeri'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pilihFoto(ImageSource.camera),
                  child: const Text('Ambil foto'),
                ),
              ),
            ],
          ),

        const SizedBox(height: AppSpacing.xl),
        _RingkasanBiaya(
          hargaPerKg: pesanan.pricePerKg,
          berat: pesanan.estimatedWeight,
          total: pesanan.totalPerkiraan,
        ),
      ],
    );
  }
}

class _RingkasanLayanan extends StatelessWidget {
  const _RingkasanLayanan({required this.layanan});

  final ServiceItem layanan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Layanan dipilih', style: tema.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(layanan.name, style: tema.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${Formats.rupiah(layanan.pricePerKg)} per kg · estimasi ${layanan.duration}',
            style: tema.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PilihanMetode extends StatelessWidget {
  const _PilihanMetode({
    required this.nilai,
    required this.opsi,
    required this.onPilih,
    required this.aktif,
  });

  final String nilai;
  final List<String> opsi;
  final ValueChanged<String> onPilih;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      children: [
        for (final metode in opsi)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InkWell(
              onTap: aktif ? () => onPilih(metode) : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: nilai == metode
                      ? AppColors.primarySoft
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: nilai == metode ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: nilai == metode
                              ? AppColors.primary
                              : AppColors.border,
                          width: nilai == metode ? 2 : 1.5,
                        ),
                      ),
                      child: nilai == metode
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        OrderLabels.metodePembayaran(metode),
                        style: tema.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RingkasanBiaya extends StatelessWidget {
  const _RingkasanBiaya({
    required this.hargaPerKg,
    required this.berat,
    required this.total,
  });

  final double hargaPerKg;
  final double? berat;
  final double total;

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
        children: [
          _baris(tema, 'Harga per kg', Formats.rupiah(hargaPerKg)),
          const SizedBox(height: AppSpacing.sm),
          _baris(tema, 'Estimasi berat', berat == null ? '—' : Formats.berat(berat)),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Perkiraan total', style: tema.textTheme.titleSmall),
                    Text(
                      'Dihitung ulang server setelah berat asli diisi.',
                      style: tema.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Text(
                Formats.rupiah(total),
                style: tema.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _baris(ThemeData tema, String label, String nilai) {
    return Row(
      children: [
        Expanded(child: Text(label, style: tema.textTheme.bodySmall)),
        Text(nilai, style: tema.textTheme.bodyMedium),
      ],
    );
  }
}

/// Detail satu layanan, dibuka dari beranda.
class LayananDetailPage extends StatelessWidget {
  const LayananDetailPage({super.key, required this.layanan});

  final ServiceItem layanan;

  static void buka(BuildContext context, ServiceItem layanan) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LayananDetailPage(layanan: layanan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final alamatApi = ApiConfig.baseUrl;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Detail layanan'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(layanan.name, style: tema.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${Formats.rupiah(layanan.pricePerKg)} per kg',
                  style: tema.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Deskripsi', style: tema.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    )),
                const SizedBox(height: AppSpacing.sm),
                Text(layanan.deskripsiTampil, style: tema.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimasi pengerjaan', style: tema.textTheme.labelSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(layanan.duration, style: tema.textTheme.titleSmall),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harga per kg', style: tema.textTheme.labelSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            Formats.rupiah(layanan.pricePerKg),
                            style: tema.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () async {
                    final hasil = await PesanFormPage.buka(context, layanan);
                    if (!context.mounted) return;
                    if (hasil == true) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Pesan layanan ini'),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Data layanan diambil dari $alamatApi',
                  style: tema.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
