import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_command_surface.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin → İşlem Kayıtları: operasyon geçmişi yüzeyi (Screen 15).
class AdminAuditPage extends ConsumerWidget {
  const AdminAuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentRoleOrNullProvider) ?? AppRole.guest;
    if (!FeaturePermission.canViewAuditLog(currentRole)) {
      return PremiumShellBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context).t('access_denied'),
                style: TextStyle(
                  color: AppThemeExtension.of(context).textSecondary,
                  fontSize: DesignTokens.fontSizeSm,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return const PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IslemKayitlariCommandSurface(),
      ),
    );
  }
}
