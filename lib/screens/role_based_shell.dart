import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_shell.dart';
import 'consultant_shell.dart';

/// Giriş sonrası rolüne göre Yönetici veya Danışman panelini gösterir.
/// Yönetici: tam dashboard, War Room, çağrı merkezi, raporlar, ekonomi, ayarlar.
/// Danışman: kendi özeti, müşteriler, ilanlar, Magic Call, takip, ayarlar.
class RoleBasedShellSelector extends ConsumerWidget {
  const RoleBasedShellSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider);
    final preferConsultant = ref.watch(preferredConsultantPanelProvider);
    if (role == null) return const _ShellLoading();
    // Yönetici kullanıcı panel tercihine göre; danışman her zaman danışman paneli.
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
    return const Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00FF41)),
            SizedBox(height: 24),
            Text(
              'Panel hazırlanıyor...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
