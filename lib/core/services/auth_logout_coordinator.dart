import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../router/app_router.dart';
import 'auth_service.dart';

/// Tek çıkış koordinatörü — çift tıklama, stale redirect ve donmayı önler.
class AuthLogoutCoordinator {
  AuthLogoutCoordinator._();

  static bool _inFlight = false;

  /// Firebase çıkışı + tek router refresh (navigasyon GoRouter redirect ile).
  static Future<void> signOut(WidgetRef ref) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      await AuthService.instance.signOut();
      ref.read(AppRouter.goRouterProvider).refresh();
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('AuthLogoutCoordinator.signOut', e, st);
      rethrow;
    } finally {
      _inFlight = false;
    }
  }
}
