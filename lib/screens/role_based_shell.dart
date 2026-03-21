import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/app_loading.dart';
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
    final role = ref.watch(displayRoleOrNullProvider);
    final preferConsultant = ref.watch(preferredConsultantPanelProvider);
    if (role == null) return const _ShellLoading();
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

class _ShellLoading extends StatelessWidget {
  const _ShellLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Açık temada scaffold beyazı "boş ekran" gibi görünmesin.
      backgroundColor: DesignTokens.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoading(),
            const SizedBox(height: 24),
            Text(
              'Panel hazırlanıyor...',
              style: TextStyle(
                color: DesignTokens.textPrimaryDark.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
