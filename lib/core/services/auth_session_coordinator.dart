import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/services/startup_role_cache.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

/// Oturumlar arası (çıkış → farklı hesap/rol) kirlenmeyi önler + ön plan token yenileme.
abstract final class AuthSessionCoordinator {
  /// Çıkış sonrası senkron sıfırlama — yeni girişten önce stale rol/shell kalmasın.
  static void resetForSignOut(WidgetRef ref, {String? previousUid}) {
    StartupRoleCache.instance.clearInMemory();
    ref.read(preferredConsultantPanelProvider.notifier).state = null;
    ref.read(overrideRoleProvider.notifier).state = null;
    ref.read(mainShellShortcutProvider.notifier).clear();
    bumpSessionEpoch(ref);
    invalidateRoleGraph(ref, uid: previousUid);
  }

  /// Yeni oturum girişi — önceki uid/rol hatası taşınmasın.
  static void prepareForLogin(WidgetRef ref, String uid) {
    StartupRoleCache.instance.clearInMemory();
    ref.read(preferredConsultantPanelProvider.notifier).state = null;
    ref.read(overrideRoleProvider.notifier).state = null;
    ref.read(mainShellShortcutProvider.notifier).clear();
    bumpSessionEpoch(ref);
    invalidateRoleGraph(ref, uid: uid);
  }

  static void bumpSessionEpoch(WidgetRef ref) {
    ref.read(authSessionEpochProvider.notifier).state++;
    ref.read(authPresentationEpochProvider.notifier).state++;
  }

  static void invalidateRoleGraph(WidgetRef ref, {String? uid}) {
    if (uid != null && uid.isNotEmpty) {
      ref.invalidate(userDocStreamProvider(uid));
    }
    ref.invalidate(primaryMembershipProvider);
    ref.invalidate(officeAccessStateProvider);
    ref.invalidate(currentRoleProvider);
    ref.invalidate(displayRoleProvider);
    ref.invalidate(currentOfficeProvider);
    ref.invalidate(officeRoleProvider);
    ref.invalidate(needsRoleSelectionProvider);
    ref.invalidate(needsOfficeSetupProvider);
    ref.invalidate(needsOfficeRecoveryProvider);
    ref.invalidate(userDocBootstrapPendingProvider);
  }

  static Future<void> persistCacheClear() => StartupRoleCache.instance.clear();

  static DateTime? _lastResumeRefresh;

  /// Uygulama öne gelince (soğuk değil, throttled).
  static Future<void> refreshOnAppResume() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    if (_lastResumeRefresh != null &&
        now.difference(_lastResumeRefresh!) < const Duration(minutes: 3)) {
      return;
    }
    _lastResumeRefresh = now;
    try {
      await user.reload();
      final after = FirebaseAuth.instance.currentUser;
      if (after == null) {
        // Bazı cihazlarda resume anında kısa süreli null görülebilir.
        // Burada zorla signOut yapmak kullanıcıyı gereksiz yere login ekranına
        // düşürebilir; bir sonraki auth event / resume ile kendini toparlar.
        return;
      }
      await after.getIdToken(true);
    } catch (e, st) {
      if (kDebugMode) {
        AppLogger.d('AuthSessionCoordinator.refreshOnAppResume', e, st);
      }
    }
  }
}
