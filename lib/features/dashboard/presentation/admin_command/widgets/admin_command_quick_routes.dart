import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminCommandRouteTile {
  const AdminCommandRouteTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class PremiumAdminQuickRoutes extends ConsumerWidget {
  const PremiumAdminQuickRoutes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    final warRoom = (flags?[AppConstants.keyFeatureWarRoom] ?? true) &&
        FeaturePermission.canViewWarRoom(role);
    final commandCenter =
        (flags?[AppConstants.keyFeatureCommandCenter] ?? true) &&
            FeaturePermission.canViewAllCalls(role);
    final l10n = AppLocalizations.of(context);

    final tiles = <AdminCommandRouteTile>[
      if (commandCenter)
        AdminCommandRouteTile(
          icon: Icons.phone_in_talk_rounded,
          title: l10n.t('nav_call_center'),
          subtitle: 'Ofis çağrı akışı ve kayıtlar',
          onTap: () {
            AppFeedback.selectionClick();
            AdminShellNav.goToCommandCenterTab(context);
          },
        ),
      if (warRoom)
        AdminCommandRouteTile(
          icon: Icons.military_tech_rounded,
          title: l10n.t('nav_war_room'),
          subtitle: 'Canlı fırsat ve ekip nabzı',
          onTap: () {
            AppFeedback.selectionClick();
            AdminShellNav.goToWarRoomTab(context);
          },
        ),
      AdminCommandRouteTile(
        icon: Icons.analytics_rounded,
        title: l10n.t('nav_reports'),
        subtitle: 'Kadro, performans ve içgörüler',
        onTap: () {
          AppFeedback.selectionClick();
          AdminShellNav.goToReportsTab(context);
        },
      ),
      if (FeaturePermission.canManageTeams(role))
        AdminCommandRouteTile(
          icon: Icons.groups_rounded,
          title: 'Kadro',
          subtitle: 'Danışmanlar ve ekip yapısı',
          onTap: () {
            AppFeedback.selectionClick();
            context.push(AppRouter.routeAdminConsultants);
          },
        ),
      if (FeaturePermission.canManagePlatformIntegrations(role))
        AdminCommandRouteTile(
          icon: Icons.hub_outlined,
          title: 'Entegrasyonlar',
          subtitle: 'Kanal bağlantıları ve kurulum',
          onTap: () {
            AppFeedback.selectionClick();
            context.push(AppRouter.routeConnectedAccounts);
          },
        ),
    ];

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminCommandTokens.horizontal,
        0,
        AdminCommandTokens.horizontal,
        AdminCommandTokens.sectionGap,
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: AdminCommandTokens.moduleGap),
            _RouteTile(tile: tiles[i], ext: ext),
          ],
        ],
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({required this.tile, required this.ext});

  final AdminCommandRouteTile tile;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: AdminCommandTokens.routeTileHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: ext.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ext.border.withValues(alpha: 0.32)),
          ),
          child: Row(
            children: [
              Icon(tile.icon, size: 20, color: ext.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tile.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: ext.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
