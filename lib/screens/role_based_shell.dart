import 'dart:async';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/auth_logout_coordinator.dart';
import 'package:emlakmaster_mobile/core/services/auth_session_coordinator.dart';
import 'package:emlakmaster_mobile/core/services/logout_flow_tracer.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/performance/shell_bootstrap_skeleton.dart';
import 'package:emlakmaster_mobile/core/performance/startup_perf_markers.dart';
import 'package:emlakmaster_mobile/core/widgets/startup_recovery_scaffold.dart';
import 'package:emlakmaster_mobile/core/services/startup_role_cache.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_shell.dart';
import 'consultant_shell.dart';

/// Çözülen kabuk türü (saf karar; widget'tan bağımsız test edilebilir).
enum ResolvedShellKind { admin, consultant }

/// Rol + panel tercihi → kabuk türü. SAF fonksiyon (yan etkisiz, test edilebilir).
///
/// Kurallar:
/// - Yalnızca gerçek yönetici (seesAdminPanel) admin kabuğunu açabilir.
/// - Yönetici, panel tercihi danışman ise danışman kabuğunu görebilir.
/// - Yönetici OLMAYAN her rol, [preferConsultant] değerinden BAĞIMSIZ olarak
///   daima danışman kabuğuna düşer (consultant → manager sızıntısı engellenir).
ResolvedShellKind resolveShellKind(AppRole role, bool? preferConsultant) {
  if (FeaturePermission.seesAdminPanel(role)) {
    return preferConsultant == true
        ? ResolvedShellKind.consultant
        : ResolvedShellKind.admin;
  }
  return ResolvedShellKind.consultant;
}

/// RBAC: Giriş sonrası rolüne göre Admin, Consultant veya Client paneli.
/// - ADMIN: Komuta Merkezi, Komuta Odası, Çağrı Merkezi, raporlar, ekonomi, ayarlar.
/// - CONSULTANT: Günüm, Müşterilerim, ilanlar, Akıllı Görüşme, takip, ayarlar.
/// - CLIENT: Arama, favoriler, mesajlar, sanal tur, profil.
class RoleBasedShellSelector extends ConsumerStatefulWidget {
  const RoleBasedShellSelector({super.key});

  @override
  ConsumerState<RoleBasedShellSelector> createState() =>
      _RoleBasedShellSelectorState();
}

class _RoleBasedShellSelectorState
    extends ConsumerState<RoleBasedShellSelector> {
  static const _recoveryDelay = Duration(seconds: 8);

  Timer? _recoveryTimer;
  String? _loadingReason;
  bool _showRecovery = false;
  ProviderSubscription<AsyncValue<AppRole>>? _roleCacheSub;
  ProviderSubscription<AsyncValue<User?>>? _uidChangeSub;

  @override
  void initState() {
    super.initState();
    _roleCacheSub = ref.listenManual(displayRoleProvider, (prev, next) {
      next.whenData((role) {
        final uid = ref.read(currentUserProvider).valueOrNull?.uid;
        if (uid == null || uid.isEmpty) return;
        unawaited(StartupRoleCache.instance.persist(uid, role));
      });
    });
    _uidChangeSub = ref.listenManual(currentUserProvider, (prev, next) {
      final prevUid = prev?.valueOrNull?.uid;
      final nextUid = next.valueOrNull?.uid;
      if (prevUid != null && prevUid != nextUid) {
        AuthSessionCoordinator.invalidateRoleGraph(ref, uid: prevUid);
      }
      if (nextUid != null && prevUid != nextUid) {
        AuthSessionCoordinator.invalidateRoleGraph(ref, uid: nextUid);
      }
    });
  }

  @override
  void dispose() {
    _recoveryTimer?.cancel();
    _roleCacheSub?.close();
    _uidChangeSub?.close();
    super.dispose();
  }

  void _trackLoadingReason(String reason) {
    if (_loadingReason == reason) return;
    final wasLoading = _loadingReason != null;
    _loadingReason = reason;
    AppLogger.state('[startup][RoleShell] loading reason=$reason');
    // Zaten yükleniyorduk ve sayaç çalışıyorsa, sebep değişimi (ör. "user doc
    // bootstrap" → "display role") SÜREYİ SIFIRLAMAZ. Aksi halde salınan/akan
    // sebepler 8sn'lik kurtarmayı sonsuza dek erteleyip kalıcı iskelet (açık
    // temada beyaz algılanan) ekrana yol açabilirdi — anayasa: asla sonsuz yük.
    if (wasLoading && _recoveryTimer != null) return;
    _recoveryTimer?.cancel();
    _showRecovery = false;
    _recoveryTimer = Timer(_recoveryDelay, () {
      if (!mounted || _loadingReason == null) return;
      AppLogger.w(
          '[startup][RoleShell] recovery fallback armed: $_loadingReason');
      setState(() => _showRecovery = true);
    });
  }

  void _clearLoadingReason() {
    if (_loadingReason == null && !_showRecovery) return;
    AppLogger.state('[startup][RoleShell] interactive again');
    StartupPerfMarkers.once('role_shell_interactive');
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    _loadingReason = null;
    _showRecovery = false;
  }

  void _retryBootstrap() {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    AppLogger.state('[startup][RoleShell] retry requested uid=${uid ?? "-"}');
    if (uid != null && uid.isNotEmpty) {
      ref.invalidate(userDocStreamProvider(uid));
    }
    ref.invalidate(primaryMembershipProvider);
    ref.invalidate(officeAccessStateProvider);
    ref.invalidate(currentRoleProvider);
    ref.invalidate(displayRoleProvider);
    setState(() {
      _showRecovery = false;
      _loadingReason = null;
    });
  }

  Widget _loadingOrRecovery(String reason) {
    _trackLoadingReason(reason);
    if (_showRecovery) {
      return StartupRecoveryScaffold(
        title: 'Alan güvenli moda alındı',
        message:
            'Rol ya da ofis bilgisi beklenenden uzun sürdü. Uygulama açık; alanı yeniden kurmayı deneyebilir ya da oturumu tazeleyebilirsiniz.',
        detail: 'Bekleyen asama: $reason',
        onPrimary: _retryBootstrap,
        secondaryLabel: 'Çıkış yap',
        onSecondary: () => AuthLogoutCoordinator.signOut(ref),
      );
    }
    return const ShellBootstrapSkeleton();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    if (uid == null || uid.isEmpty) {
      if (LogoutFlowTracer.isActive) {
        LogoutFlowTracer.step('LOGOUT_FLOW', 'RoleShell uid=null shrink');
      }
      _clearLoadingReason();
      // Çıkış sonrası router /login'e yönlendirir; skeleton donmasını önle.
      return const SizedBox.shrink();
    }
    // Router ile aynı kaynak: currentRoleProvider (+ isteğe bağlı override) → displayRoleProvider.
    // users/{uid}.role tek başına ofis üyeliği rolüyle çakışmasın diye doc bootstrap / gate’lerde bekle.
    if (ref.watch(needsRoleSelectionProvider) ||
        ref.watch(needsOfficeSetupProvider) ||
        ref.watch(needsOfficeRecoveryProvider)) {
      return const _ShellRouterGatePending();
    }
    if (ref.watch(userDocBootstrapPendingProvider)) {
      final cached = StartupRoleCache.instance.roleForUser(uid);
      if (cached == null) {
        return _loadingOrRecovery('user doc bootstrap');
      }
    }
    final roleAsync = ref.watch(displayRoleProvider);
    final cachedRole = StartupRoleCache.instance.roleForUser(uid);

    if (roleAsync.isLoading && cachedRole != null) {
      return _buildForRole(context, ref, cachedRole);
    }

    return roleAsync.when(
      loading: () => cachedRole != null
          ? _buildForRole(context, ref, cachedRole)
          : _loadingOrRecovery('display role'),
      error: (e, st) {
        final liveUid = FirebaseAuth.instance.currentUser?.uid;
        if (liveUid == null || liveUid != uid) {
          return _loadingOrRecovery('role uid mismatch recovery');
        }
        _clearLoadingReason();
        AppLogger.e('[startup][RoleShell] displayRoleProvider error', e, st);
        return _ShellRoleErrorScreen(error: e, uid: uid);
      },
      data: (role) {
        _clearLoadingReason();
        return _buildForRole(context, ref, role);
      },
    );
  }

  Widget _buildForRole(BuildContext context, WidgetRef ref, AppRole role) {
    AppLogger.state('[startup][RoleShell] resolved shell for role=$role');
    StartupPerfMarkers.once('role_shell_resolved');
    final preferConsultant = ref.watch(preferredConsultantPanelProvider);
    switch (resolveShellKind(role, preferConsultant)) {
      case ResolvedShellKind.admin:
        return const AdminShellPage();
      case ResolvedShellKind.consultant:
        return const ConsultantShellPage();
    }
  }
}

/// Rol stream’i hata verince boş/siyah gövde yerine görünür kurtarma.
class _ShellRoleErrorScreen extends ConsumerWidget {
  const _ShellRoleErrorScreen({required this.error, required this.uid});

  final Object error;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveUid = FirebaseAuth.instance.currentUser?.uid;
    if (liveUid == null || liveUid != uid) {
      return const ShellBootstrapSkeleton();
    }
    final safeDetail = userFacingErrorMessage(error, context: 'role_shell');
    AppLogger.e('[startup][RoleShell] displayRoleProvider error (user-facing: $safeDetail)', error);
    return StartupRecoveryScaffold(
      title: 'Rol bilgisi yüklenemedi',
      message:
          'Oturum açıldı ancak rol profiliniz henüz yüklenemedi. Bağlantınızı kontrol edip yeniden deneyebilir ya da oturumu tazeleyebilirsiniz.',
      detail: kDebugMode ? error.toString() : safeDetail,
      onPrimary: () {
        AuthSessionCoordinator.invalidateRoleGraph(ref, uid: uid);
      },
      secondaryLabel: 'Çıkış yap',
      onSecondary: () => AuthLogoutCoordinator.signOut(ref),
    );
  }
}

/// Router rol/ofis kapısına yönlendirirken tam ekran spinner göstermez.
///
/// Normal akışta router birkaç on ms içinde rol/ofis kapısına (gate/recovery)
/// yönlendirir ve bu widget unmount olur. Ancak release zamanlaması / router
/// redirect yarışı nedeniyle kapı durumu (`needsRoleSelection` /
/// `needsOfficeSetup` / `needsOfficeRecovery`) sürer ve `/` üzerinde takılı
/// kalırsa, bu nötr gövde sonsuza dek BOŞ/BEYAZ kalmamalıdır (anayasa:
/// error-resilience — asla kalıcı boş ekran, asla sonsuz bekleme).
/// Bu yüzden kısa nötr gösterimden sonra görünür bir kurtarma + "Tekrar dene"
/// sunulur; yeniden deneme kapı/rol grafiğini tazeleyerek router'ı çözmeye iter.
class _ShellRouterGatePending extends ConsumerStatefulWidget {
  const _ShellRouterGatePending();

  @override
  ConsumerState<_ShellRouterGatePending> createState() =>
      _ShellRouterGatePendingState();
}

class _ShellRouterGatePendingState
    extends ConsumerState<_ShellRouterGatePending> {
  static const _recoveryDelay = Duration(seconds: 8);

  Timer? _timer;
  bool _showRecovery = false;

  @override
  void initState() {
    super.initState();
    _armTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = Timer(_recoveryDelay, () {
      if (!mounted || _showRecovery) return;
      AppLogger.w(
          '[startup][RoleShell] router gate pending timeout; recovery escape');
      setState(() => _showRecovery = true);
    });
  }

  void _retry() {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    AppLogger.state('[startup][RoleShell] gate-pending retry uid=${uid ?? "-"}');
    if (uid != null && uid.isNotEmpty) {
      ref.invalidate(userDocStreamProvider(uid));
    }
    ref.invalidate(primaryMembershipProvider);
    ref.invalidate(officeAccessStateProvider);
    ref.invalidate(currentRoleProvider);
    ref.invalidate(displayRoleProvider);
    setState(() => _showRecovery = false);
    _armTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_showRecovery) {
      return StartupRecoveryScaffold(
        title: 'Alan hazırlanıyor',
        message:
            'Hesap ve ofis bilginiz beklenenden uzun sürdü. Uygulama açık; '
            'alanı yeniden kurmayı deneyebilir ya da oturumu tazeleyebilirsiniz.',
        onPrimary: _retry,
        secondaryLabel: 'Çıkış yap',
        onSecondary: () => AuthLogoutCoordinator.signOut(ref),
      );
    }
    // Nötr boş gövde yerine markalı iskelet: açık temada "beyaz ekran" algısı
    // yerine kasıtlı bir "alan hazırlanıyor" yüklemesi gösterilir.
    return const ShellBootstrapSkeleton();
  }
}
