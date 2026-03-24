import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
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
      return const _ShellLoading();
    }
    final docAsync = ref.watch(userDocStreamProvider(uid));
    return docAsync.when(
      loading: () => const _ShellLoading(),
      error: (_, __) => const _ShellLoading(),
      data: (doc) {
        if (doc == null) {
          // Firestore users/{uid} yok — router rol seçimine göndermeli; yanlışlıkla buradaysak bekle.
          return const _ShellLoading();
        }
        final role = AppRole.fromFirestoreRole(doc.role);
        return _buildForRole(context, ref, role);
      },
    );
  }

  Widget _buildForRole(BuildContext context, WidgetRef ref, AppRole role) {
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
                color: AppThemeExtension.of(context).textPrimary.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
