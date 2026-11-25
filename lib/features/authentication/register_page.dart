import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/inline_notice.dart';

/// Registrasi hanya untuk CUSTOMER.
///
/// Backend selalu membuat akun dengan role CUSTOMER pada endpoint ini, jadi
/// aplikasi tidak menampilkan pilihan role sama sekali.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _ulangiSandi = TextEditingController();
  String? _pesanGalat;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _sandi.dispose();
    _ulangiSandi.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final session = AppScope.sessionOf(context);
    setState(() => _pesanGalat = null);

    final berhasil = await session.daftar(
      name: _nama.text,
      email: _email.text,
      password: _sandi.text,
    );

    if (!mounted) return;

    if (berhasil) {
      // RootGate langsung menampilkan beranda customer setelah sesi aktif.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _pesanGalat = session.pesanAksi);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final session = AppScope.sessionOf(context);
    final sedangProses = session.sedangProses;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: sedangProses ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Daftar akun'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Buat akun RENOVA', style: tema.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Akun ini dipakai untuk memesan dan memantau laundry Anda.',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    AppTextField(
                      label: 'Nama lengkap',
                      controller: _nama,
                      hint: 'Nama Anda',
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      validator: Validators.nama,
                      enabled: !sedangProses,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      hint: 'nama@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                      enabled: !sedangProses,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    PasswordField(
                      label: 'Kata sandi',
                      controller: _sandi,
                      hint: 'Minimal 8 karakter',
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: Validators.sandiBaru,
                      enabled: !sedangProses,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    PasswordField(
                      label: 'Ulangi kata sandi',
                      controller: _ulangiSandi,
                      hint: 'Ketik ulang kata sandi',
                      textInputAction: TextInputAction.done,
                      validator: (nilai) =>
                          Validators.konfirmasiSandi(nilai, _sandi.text),
                      enabled: !sedangProses,
                      onFieldSubmitted: (_) => _daftar(),
                    ),

                    if (_pesanGalat != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      InlineNotice(pesan: _pesanGalat!, galat: true),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: sedangProses ? null : _daftar,
                      child: sedangProses
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Daftar'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Akun admin hanya dibuat oleh pengelola sistem, bukan '
                      'melalui halaman ini.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
