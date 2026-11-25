import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/di/app_scope.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user.dart';
import '../../shared/widgets/branding.dart';
import '../../shared/widgets/detail_section.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/inline_notice.dart';

/// Profil akun yang sedang masuk, dipakai bersama oleh admin dan customer.
///
/// Mengubah nama dan mengganti kata sandi memakai endpoint yang sama
/// (`PATCH /api/auth/me`); tidak ada hapus akun karena backend tidak
/// menyediakannya.
class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final user = session.user;
        if (user == null) return const SizedBox.shrink();

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _KartuAkun(user: user),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _AksiAkun(user: user),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _TentangAplikasi(user: user),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: OutlinedButton(
                onPressed: () async {
                  final setuju = await konfirmasi(
                    context,
                    judul: 'Keluar dari akun?',
                    isi: 'Anda perlu masuk kembali untuk melihat pesanan.',
                    labelYa: 'Keluar',
                  );
                  if (!setuju || !context.mounted) return;
                  await session.keluar();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('Keluar'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KartuAkun extends StatelessWidget {
  const _KartuAkun({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            user.inisial,
            style: tema.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: tema.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(user.email, style: tema.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Peran: ${user.role.label}',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AksiAkun extends StatelessWidget {
  const _AksiAkun({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      judul: 'Pengaturan akun',
      children: [
        _BarisAksi(
          judul: 'Ubah nama',
          keterangan: 'Nama yang tampil di pesanan Anda.',
          onTap: () => _ubahNama(context, user),
        ),
        const Divider(height: 1),
        _BarisAksi(
          judul: 'Ganti kata sandi',
          keterangan: 'Perlu kata sandi saat ini untuk mengonfirmasi.',
          onTap: () => _gantiSandi(context),
        ),
      ],
    );
  }

  Future<void> _ubahNama(BuildContext context, User user) async {
    final session = AppScope.sessionOf(context);
    final repo = AppScope.of(context).authRepository;
    final controller = TextEditingController(text: user.name);
    final formKey = GlobalKey<FormState>();
    var mengirim = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> simpan() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              setDialogState(() => mengirim = true);

              try {
                final terbaru = await repo.updateProfile(name: controller.text);
                session.perbaruiUser(terbaru);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                tampilkanPesan(context, 'Nama berhasil diperbarui.');
              } catch (error) {
                if (!dialogContext.mounted) return;
                setDialogState(() => mengirim = false);
                tampilkanPesan(context, pesanKesalahan(error), galat: true);
              }
            }

            return AlertDialog(
              title: const Text('Ubah nama'),
              content: Form(
                key: formKey,
                child: AppTextField(
                  label: 'Nama',
                  controller: controller,
                  hint: 'Nama Anda',
                  validator: Validators.nama,
                  enabled: !mengirim,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: mengirim ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: mengirim ? null : simpan,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: mengirim ? const ButtonSpinner() : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _gantiSandi(BuildContext context) async {
    final repo = AppScope.of(context).authRepository;
    final formKey = GlobalKey<FormState>();
    final lama = TextEditingController();
    final baru = TextEditingController();
    final ulang = TextEditingController();
    var mengirim = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> simpan() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              setDialogState(() => mengirim = true);

              try {
                await repo.updateProfile(
                  currentPassword: lama.text,
                  newPassword: baru.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                tampilkanPesan(context, 'Kata sandi berhasil diganti.');
              } on ApiException catch (error) {
                if (!dialogContext.mounted) return;
                setDialogState(() => mengirim = false);
                tampilkanPesan(context, error.message, galat: true);
              }
            }

            return AlertDialog(
              title: const Text('Ganti kata sandi'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PasswordField(
                        label: 'Kata sandi saat ini',
                        controller: lama,
                        validator: Validators.sandiMasuk,
                        enabled: !mengirim,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PasswordField(
                        label: 'Kata sandi baru',
                        controller: baru,
                        hint: 'Minimal 8 karakter',
                        validator: Validators.sandiBaru,
                        enabled: !mengirim,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PasswordField(
                        label: 'Ulangi kata sandi baru',
                        controller: ulang,
                        validator: (nilai) =>
                            Validators.konfirmasiSandi(nilai, baru.text),
                        enabled: !mengirim,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: mengirim ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: mengirim ? null : simpan,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: mengirim ? const ButtonSpinner() : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    lama.dispose();
    baru.dispose();
    ulang.dispose();
  }
}

class _BarisAksi extends StatelessWidget {
  const _BarisAksi({
    required this.judul,
    required this.keterangan,
    required this.onTap,
  });

  final String judul;
  final String keterangan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: tema.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(keterangan, style: tema.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TentangAplikasi extends StatelessWidget {
  const _TentangAplikasi({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSection(
          judul: 'Informasi akun',
          children: [
            DetailRow(
              label: 'Nama',
              nilai: user.name,
            ),
            DetailRow(label: 'Email', nilai: user.email),
            DetailRow(label: 'Peran', nilai: user.role.label),
            DetailRow(
              label: 'Terdaftar',
              nilai: Formats.tanggalPanjang(user.createdAt),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Column(
            children: [
              const RenovaLogo(size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'RENOVA · Laundry',
                style: tema.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Terhubung ke ${ApiConfig.baseUrl}',
                style: tema.textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              if (ApiConfig.memakaiAlamatBawaan) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: InlineNotice(
                    pesan: 'Alamat server masih bawaan pengembangan. Untuk '
                        'perangkat nyata, jalankan aplikasi dengan '
                        '--dart-define=API_BASE_URL=<alamat server>.',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
