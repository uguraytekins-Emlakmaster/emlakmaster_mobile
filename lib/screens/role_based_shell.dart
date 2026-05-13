import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/widgets/app_loading.dart';
import 'package:emlakmaster_mobile/core/widgets/startup_recovery_scaffold.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_shell.dart';
import 'client_shell.dart';
import 'consultant_shell.dart';

/// RBAC: Giriş sonrası rolüne göre Admin, Consultant veya Client paneli.
/// - ADMIN: Dashboard, War Room, çağrı merkezi, raporlar, ekonomi, ayarlar.
/// - CONSULTANT: Özetim, müşteriler, ilanlar, Magic Call, takip, ayarlar.
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

  @override
  void dispose() {
    _recoveryTimer?.cancel();
    super.dispose();
  }

  void _trackLoadingReason(String reason) {
    if (_loadingReason == reason) return;
    _recoveryTimer?.cancel();
    _loadingReason = reason;
    _showRecovery = false;
    AppLogger.state('[startup][RoleShell] loading reason=$reason');
    _recoveryTimer = Timer(_recoveryDelay, () {
      if (!mounted || _loadingReason != reason) return;
      AppLogger.w('[startup][RoleShell] recovery fallback armed: $reason');
      setState(() => _showRecovery = true);
    });
  }

  void _clearLoadingReason() {
    if (_loadingReason == null && !_showRecovery) return;
    AppLogger.state('[startup][RoleShell] interactive again');
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
        onSecondary: () => AuthService.instance.signOut(),
      );
    }
    return _ShellLoading(reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    if (uid == null || uid.isEmpty) {
      return _loadingOrRecovery('no uid');
    }
    // Router ile aynı kaynak: currentRoleProvider (+ isteğe bağlı override) → displayRoleProvider.
    // users/{uid}.role tek başına ofis üyeliği rolüyle çakışmasın diye doc bootstrap / gate’lerde bekle.
    if (ref.watch(userDocBootstrapPendingProvider)) {
      return _loadingOrRecovery('userDocBootstrapPending');
    }
    if (ref.watch(needsRoleSelectionProvider)) {
      return _loadingOrRecovery('needsRoleSelection');
    }
    if (ref.watch(needsOfficeSetupProvider)) {
      return _loadingOrRecovery('needsOfficeSetup');
    }
    if (ref.watch(needsOfficeRecoveryProvider)) {
      return _loadingOrRecovery('needsOfficeRecovery');
    }
    final roleAsync = ref.watch(displayRoleProvider);
    return roleAsync.when(
      loading: () => _loadingOrRecovery('displayRoleProvider.loading'),
      error: (e, st) {
        _clearLoadingReason();
        AppLogger.e('[startup][RoleShell] displayRoleProvider error', e, st);
        return _ShellRoleErrorScreen(error: e);
      },
      data: (role) {
        _clearLoadingReason();
        return _buildForRole(context, ref, role);
      },
    );
  }

  Widget _buildForRole(BuildContext context, WidgetRef ref, AppRole role) {
    AppLogger.state('[startup][RoleShell] resolved shell for role=$role');
    final preferConsultant = ref.watch(preferredConsultantPanelProvider);
    if (FeaturePermission.seesClientPanel(role)) return const ClientShellPage();
    final forceConsultant = preferConsultant == true;
    final forceAdmin = preferConsultant == false;
    if (FeaturePermission.seesAdminPanel(role)) {
      if (forceConsultant) return const ConsultantShellPage();
      return const AdminShellPage();
    }
    if (forceAdmin) return const AdminShellPage();
    return const ConsultantShellPage();
  }
}

/// Rol stream’i hata verince boş/siyah gövde yerine görünür kurtarma.
class _ShellRoleErrorScreen extends ConsumerWidget {
  const _ShellRoleErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    return StartupRecoveryScaffold(
      title: 'Rol bilgisi yüklenemedi',
      message:
          'Bağlantı ya da sunucu yanıtı alınırken bir aksama oldu. Yeniden deneyebilir ya da oturumu tazeleyebilirsiniz.',
      detail: error.toString(),
      onPrimary: uid == null
          ? null
          : () {
              ref.invalidate(userDocStreamProvider(uid));
              ref.invalidate(currentRoleProvider);
              ref.invalidate(displayRoleProvider);
            },
      secondaryLabel: 'Çıkış yap',
      onSecondary: () => AuthService.instance.signOut(),
    );
  }
}

class _ShellLoading extends StatelessWidget {
  const _ShellLoading({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Açık temada scaffold beyazı "boş ekran" gibi görünmesin.
      backgroundColor: AppThemeExtension.of(context).background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoading(),
            const SizedBox(height: 24),
            Text(
              'Panel hazırlanıyor...',
              style: TextStyle(
                color: AppThemeExtension.of(context)
                    .textPrimary
                    .withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                reason,
                style: TextStyle(
                  color: AppThemeExtension.of(context)
                      .textSecondary
                      .withValues(alpha: 0.72),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
