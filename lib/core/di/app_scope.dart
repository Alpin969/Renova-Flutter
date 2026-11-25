import 'package:flutter/widgets.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/services/photo_picker.dart';
import '../state/refresh_bus.dart';
import '../state/session_controller.dart';

/// Semua dependensi aplikasi yang dibuat satu kali saat start.
class AppDependencies {
  const AppDependencies({
    required this.session,
    required this.authRepository,
    required this.serviceRepository,
    required this.orderRepository,
    required this.photoPicker,
    required this.refreshBus,
    required this.navigatorKey,
  });

  final SessionController session;
  final AuthRepository authRepository;
  final ServiceRepository serviceRepository;
  final OrderRepository orderRepository;
  final PhotoPicker photoPicker;
  final RefreshBus refreshBus;
  final GlobalKey<NavigatorState> navigatorKey;
}

/// Menyediakan [AppDependencies] ke seluruh pohon widget.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope harus ada di atas widget ini.');
    return scope!.dependencies;
  }

  static SessionController sessionOf(BuildContext context) =>
      of(context).session;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
