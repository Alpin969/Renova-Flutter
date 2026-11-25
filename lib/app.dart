import 'package:flutter/material.dart';

import 'core/di/app_scope.dart';
import 'core/network/api_client.dart';
import 'core/state/refresh_bus.dart';
import 'core/state/session_controller.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/service_repository.dart';
import 'data/services/photo_picker.dart';
import 'data/services/token_holder.dart';
import 'data/services/token_storage.dart';
import 'features/authentication/root_gate.dart';

/// Menyusun semua dependensi aplikasi dan menjalankan aplikasinya.
///
/// Urutannya penting: klien HTTP butuh token, sedangkan penanganan token
/// ditolak butuh sesi. Variabel `late` memutus lingkaran itu tanpa membuat
/// keduanya saling bergantung saat dibuat.
class RenovaApp extends StatefulWidget {
  const RenovaApp({super.key});

  @override
  State<RenovaApp> createState() => _RenovaAppState();
}

class _RenovaAppState extends State<RenovaApp> {
  late final AppDependencies _deps;
  late final ApiClient _api;

  @override
  void initState() {
    super.initState();
    _deps = _susunDependensi();
  }

  AppDependencies _susunDependensi() {
    final holder = TokenHolder();
    final navigatorKey = GlobalKey<NavigatorState>();
    final refreshBus = RefreshBus();

    late final SessionController session;

    final api = ApiClient(
      tokenProvider: () => holder.token ?? '',
      onUnauthorized: () => session.sesiHabis(),
    );
    _api = api;

    final authRepository = AuthRepository(api);
    session = SessionController(
      authRepository: authRepository,
      tokenStorage: TokenStorage(),
      tokenHolder: holder,
    );

    // Saat sesi berakhir, layar yang sedang terbuka di atas root ditutup
    // supaya pengguna kembali ke halaman login, bukan tertinggal di layar
    // data yang sudah tidak boleh diakses.
    session.onSesiSelesai = () {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    };

    return AppDependencies(
      session: session,
      authRepository: authRepository,
      serviceRepository: ServiceRepository(api),
      orderRepository: OrderRepository(api),
      photoPicker: PhotoPicker(),
      refreshBus: refreshBus,
      navigatorKey: navigatorKey,
    );
  }

  @override
  void dispose() {
    _deps.session.dispose();
    _deps.refreshBus.dispose();
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: _deps,
      child: MaterialApp(
        title: 'RENOVA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorKey: _deps.navigatorKey,
        home: const RootGate(),
      ),
    );
  }
}
