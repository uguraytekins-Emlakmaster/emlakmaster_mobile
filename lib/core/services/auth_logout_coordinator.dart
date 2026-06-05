import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import '../logging/app_logger.dart';
import '../router/app_router.dart';
import 'auth_service.dart';
import 'auth_session_coordinator.dart';
import 'google_auth_service.dart';
import 'login_attempt_guard.dart';
import 'logout_flow_tracer.dart';

/// Tek çıkış koordinatörü — çift tıklama, stale redirect ve login donmasını önler.
class AuthLogoutCoordinator {
  AuthLogoutCoordinator._();

  static bool _inFlight = false;

  /// Firebase çıkışı + login sunum katmanını sıfırla + tek navigasyon.
  ///
  /// [dismissOverlayFirst]: hesap sheet — barrier animasyonu için kısa gecikme.
  static Future<void> signOut(
    WidgetRef ref, {
    bool dismissOverlayFirst = false,
    String source = 'unknown',
  }) async {
    if (_inFlight) {
      LogoutFlowTracer.step('LOGOUT_FLOW', 'ignored duplicate inFlight source=$source');
      return;
    }
    _inFlight = true;
    LogoutFlowTracer.begin(source);
    try {
      if (dismissOverlayFirst) {
        LogoutFlowTracer.step('LOGOUT_FLOW', 'overlay settle 120ms');
        await LogoutFlowTracer.watch(
          'overlay_settle',
          Future<void>.delayed(const Duration(milliseconds: 120)),
        );
      }

      final uid = _readUidBeforeSignOut(ref);
      LogoutFlowTracer.step('AUTH_STATE', 'uidBefore=${uid ?? "-"}');

      // 1) Firebase oturumu kapat (senkron currentUser null).
      LogoutFlowTracer.step('LOGOUT_FLOW', 'AuthService.signOut start');
      await LogoutFlowTracer.watch(
        'auth_service_sign_out',
        AuthService.instance.signOut(),
      );
      LogoutFlowTracer.step('AUTH_STATE', 'liveUid=${FirebaseAuth.instance.currentUser?.uid ?? "null"}');

      // 2) Senkron cross-session sıfırlama — farklı rol/h esap girişinde stale state kalmasın.
      AuthSessionCoordinator.resetForSignOut(ref, previousUid: uid);
      LogoutFlowTracer.step('PROVIDER_RESET', 'sync cross-session reset done');

      // 3) Hemen login'e git.
      final router = ref.read(AppRouter.goRouterProvider);
      LogoutFlowTracer.step('ROUTER_REDIRECT', 'go /login from=${router.state.uri.path}');
      router.go(AppRouter.routeLogin);

      // 4) Kalıcı cache + router refresh arka planda.
      unawaited(_finishPresentationReset(ref));

      LogoutFlowTracer.end('navigated');
    } catch (e, st) {
      LogoutFlowTracer.fail(e, st);
      if (kDebugMode) AppLogger.e('AuthLogoutCoordinator.signOut', e, st);
      rethrow;
    } finally {
      _inFlight = false;
    }
  }

  static Future<void> _finishPresentationReset(WidgetRef ref) async {
    try {
      LogoutFlowTracer.step('PROVIDER_RESET', 'persist cache clear start');
      await LogoutFlowTracer.watch(
        'startup_role_cache_clear',
        AuthSessionCoordinator.persistCacheClear(),
      );
      LoginAttemptGuard.clear();
      GoogleAuthService.instance.resetAfterLogout();

      await Future<void>.delayed(const Duration(milliseconds: 32));
      ref.read(AppRouter.goRouterProvider).refresh();
      LogoutFlowTracer.step('ROUTER_REDIRECT', 'refresh after reset');
    } catch (e, st) {
      LogoutFlowTracer.step('PROVIDER_RESET', 'background error $e');
      if (kDebugMode) AppLogger.e('AuthLogoutCoordinator._finishPresentationReset', e, st);
    }
  }

  static String? _readUidBeforeSignOut(WidgetRef ref) {
    final fromStream = ref.read(currentUserProvider).valueOrNull?.uid;
    if (fromStream != null && fromStream.isNotEmpty) return fromStream;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
