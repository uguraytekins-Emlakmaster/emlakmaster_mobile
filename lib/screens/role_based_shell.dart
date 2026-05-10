import 'package:flutter/foundation.dart';

import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/app_loading.dart';
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
class RoleBasedShellSelector extends ConsumerWidget {
  const RoleBasedShellSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    if (uid == null || uid.isEmpty) {
      if (kDebugMode) {
        debugPrint('[RoleShell] showing loading: no uid');
      }
      return const _ShellLoading();
    }
    // Router ile aynı kaynak: currentRoleProvider (+ isteğe bağlı override) → displayRoleProvider.
    // users/{uid}.role tek başına ofis üyeliği rolüyle çakışmasın diye doc bootstrap / gate’lerde bekle.
    if (ref.watch(userDocBootstrapPendingProvider)) {
      if (kDebugMode) {
        debugPrint('[RoleShell] showing loading: userDocBootstrapPending');
      }
      return const _ShellLoading();
    }
    if (ref.watch(needsRoleSelectionProvider)) {
      if (kDebugMode) {
        debugPrint('[RoleShell] showing loading: needsRoleSelection');
      }
      return const _ShellLoading();
    }
    if (ref.watch(needsOfficeSetupProvider)) {
      if (kDebugMode) {
        debugPrint('[RoleShell] showing loading: needsOfficeSetup');
      }
      return const _ShellLoading();
    }
    if (ref.watch(needsOfficeRecoveryProvider)) {
      if (kDebugMode) {
        debugPrint('[RoleShell] showing loading: needsOfficeRecovery');
      }
      return const _ShellLoading();
    }
    final roleAsync = ref.watch(displayRoleProvider);
    return roleAsync.when(
      loading: () {
        if (kDebugMode) {
          debugPrint(
              '[RoleShell] showing loading: displayRoleProvider.loading');
        }
        return const _ShellLoading();
      },
      error: (e, st) {
        debugPrint('[RoleShell] displayRoleProvider error: $e');
        debugPrint('$st');
        return _ShellRoleErrorScreen(error: e);
      },
      data: (role) => _buildForRole(context, ref, role),
    );
  }

  Widget _buildForRole(BuildContext context, WidgetRef ref, AppRole role) {
    if (kDebugMode) {
      debugPrint('[RoleShell] resolved shell for role=$role');
    }
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
    final ext = AppThemeExtension.of(context);
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: ext.accent.withValues(alpha: 0.9),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  'Rol bilgisi yüklenemedi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontSize: DesignTokens.fontSizeLg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                Text(
                  'Ağ veya sunucu yanıtı beklenirken sorun oluştu. Tekrar deneyebilir veya oturumu yenileyebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: DesignTokens.fontSizeSm,
                    height: 1.45,
                  ),
                ),
                if (uid != null) ...[
                  const SizedBox(height: DesignTokens.space5),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(userDocStreamProvider(uid));
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tekrar dene'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellLoading extends StatelessWidget {
  const _ShellLoading();

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
          ],
        ),
      ),
    );
  }
}
