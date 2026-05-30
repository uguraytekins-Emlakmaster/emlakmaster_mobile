import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import '../logging/app_logger.dart';
import '../router/app_router.dart';
import 'auth_service.dart';
import 'auth_firestore_gate.dart';
import 'google_auth_service.dart';
import 'login_attempt_guard.dart';
import 'startup_role_cache.dart';

/// Tek çıkış koordinatörü — çift tıklama, stale redirect ve login donmasını önler.
class AuthLogoutCoordinator {
  AuthLogoutCoordinator._();

  static bool _inFlight = false;

  /// Firebase çıkışı + login sunum katmanını sıfırla + tek navigasyon.
  ///
  /// [dismissOverlayFirst]: hesap sheet gibi modal üstünden çıkışta barrier kapanana kadar bekle.
  static Future<void> signOut(
    WidgetRef ref, {
    bool dismissOverlayFirst = false,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      if (dismissOverlayFirst) {
        await Future<void>.delayed(const Duration(milliseconds: 320));
      }

      final uid = _readUidBeforeSignOut(ref);
      await AuthService.instance.signOut();
      await AuthFirestoreGate.waitUntilSignedOut();
      await StartupRoleCache.instance.clear();
      _resetPresentationState(ref, previousUid: uid);

      ref.read(authPresentationEpochProvider.notifier).state++;

      await Future<void>.delayed(Duration.zero);
      await SchedulerBinding.instance.endOfFrame;

      final router = ref.read(AppRouter.goRouterProvider);
      if (router.state.uri.path != AppRouter.routeLogin) {
        router.go(AppRouter.routeLogin);
      } else {
        router.refresh();
      }
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('AuthLogoutCoordinator.signOut', e, st);
      rethrow;
    } finally {
      _inFlight = false;
    }
  }

  static String? _readUidBeforeSignOut(WidgetRef ref) {
    final fromStream = ref.read(currentUserProvider).valueOrNull?.uid;
    if (fromStream != null && fromStream.isNotEmpty) return fromStream;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  static void _resetPresentationState(
    WidgetRef ref, {
    String? previousUid,
  }) {
    LoginAttemptGuard.clear();
    GoogleAuthService.instance.resetAfterLogout();
    ref.read(overrideRoleProvider.notifier).state = null;

    if (previousUid != null && previousUid.isNotEmpty) {
      ref.invalidate(userDocStreamProvider(previousUid));
    }
    ref.invalidate(primaryMembershipProvider);
    ref.invalidate(officeAccessStateProvider);
    ref.invalidate(currentRoleProvider);
    ref.invalidate(displayRoleProvider);
  }
}
