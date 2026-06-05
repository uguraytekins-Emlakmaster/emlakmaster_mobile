import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/auth_logout_coordinator.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Ofis yokken: oluştur veya katıl seçimi (merkezi yönlendirme).
class OfficeGatePage extends ConsumerWidget {
  const OfficeGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumPageHeader(
                title: l10n.t('office_gate_title'),
                subtitle: l10n.t('office_gate_sub'),
              ),
              const SizedBox(height: 32),
              _Tile(
                icon: Icons.add_business_rounded,
                title: l10n.t('office_create'),
                subtitle: l10n.t('office_create_sub'),
                onTap: () {
                  AppFeedback.selectionClick();
                  context.push(AppRouter.routeOfficeCreate);
                },
              ),
              const SizedBox(height: 12),
              _Tile(
                icon: Icons.vpn_key_rounded,
                title: l10n.t('office_join'),
                subtitle: l10n.t('office_join_sub'),
                onTap: () {
                  AppFeedback.selectionClick();
                  context.push(AppRouter.routeOfficeJoin);
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  AppFeedback.lightImpact();
                  await AuthLogoutCoordinator.signOut(ref);
                },
                child: Text(
                  l10n.t('settings_logout'),
                  style:
                      TextStyle(color: ext.foregroundSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surfaceElevated,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              Icon(icon, color: ext.accent, size: 28),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ext.foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ext.foregroundSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ext.foregroundSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
