import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/di/app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/branding.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/inline_notice.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final session = AppScope.sessionOf(context);
    await session.masuk(
      email: _email.text,
      password: _password.text,
    );
    // Perpindahan layar ditangani RootGate: begitu status sesi menjadi
    // "masuk", layar sesuai role langsung ditampilkan.
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final session = AppScope.sessionOf(context);
    final sedangProses = session.sedangProses;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: RenovaLogo(size: 56),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Masuk ke RENOVA', style: tema.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Kelola dan pantau pesanan laundry Anda.',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (session.pesanSesi != null) ...[
                      InlineNotice(pesan: session.pesanSesi!),
                      const SizedBox(height: AppSpacing.lg),
                    ],

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
                      controller: _password,
                      hint: 'Masukkan kata sandi',
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: Validators.sandiMasuk,
                      enabled: !sedangProses,
                      onFieldSubmitted: (_) => _masuk(),
                    ),

                    if (session.pesanAksi != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      InlineNotice(pesan: session.pesanAksi!, galat: true),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: sedangProses ? null : _masuk,
                      child: sedangProses
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: sedangProses
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegisterPage(),
                                ),
                              ),
                      child: const Text('Belum punya akun? Daftar'),
                    ),

                    if (ApiConfig.memakaiAlamatBawaan) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Server: ${ApiConfig.baseUrl}',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
