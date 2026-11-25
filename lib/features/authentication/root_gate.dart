import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../core/state/session_controller.dart';
import '../admin/admin_shell.dart';
import '../customer/customer_shell.dart';
import 'login_page.dart';
import 'splash_page.dart';

/// Menentukan layar mana yang tampil berdasarkan keadaan sesi.
///
/// Semua perpindahan setelah login mengikuti nilai `role` dari backend:
/// ADMIN ke dashboard admin, CUSTOMER ke beranda customer.
class RootGate extends StatefulWidget {
  const RootGate({super.key, this.initialIndex = 0});

  /// Menu yang dibuka pertama kali setelah masuk. Bawaannya menu pertama.
  final int initialIndex;

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _sudahMulai = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sudahMulai) return;
    _sudahMulai = true;

    final session = AppScope.sessionOf(context);
    // Dipanggil setelah frame pertama supaya splash sempat tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) => session.pulihkanSesi());
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        switch (session.status) {
          case SessionStatus.memuat:
            return const SplashPage();

          case SessionStatus.gagalMemuat:
            return SplashGagalPage(
              pesan: session.pesanGagalPulih ?? 'Server belum dapat dihubungi.',
              onCobaLagi: session.pulihkanSesi,
              onMasukUlang: session.keluar,
            );

          case SessionStatus.tamu:
            return const LoginPage();

          case SessionStatus.masuk:
            final user = session.user;
            if (user == null) return const SplashPage();
            return user.role.isAdmin
                ? AdminShell(initialIndex: widget.initialIndex)
                : CustomerShell(initialIndex: widget.initialIndex);
        }
      },
    );
  }
}
