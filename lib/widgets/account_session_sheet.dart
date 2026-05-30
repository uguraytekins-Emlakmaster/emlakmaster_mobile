import 'dart:async';

import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/auth_logout_coordinator.dart';
import 'package:emlakmaster_mobile/core/services/logout_flow_tracer.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Premium hesap / oturum paneli — ana ekran avatarından.
Future<void> showAccountSessionSheet(
    BuildContext context, WidgetRef ref) async {
  await AppFeedback.lightImpact();
  if (!context.mounted) return;
  await showPremiumScrollableBottomSheet<void>(
    context: context,
    builder: (ctx) => const _AccountSessionSheet(),
  );
}

class _AccountSessionSheet extends ConsumerWidget {
  const _AccountSessionSheet();

  static String _activePanelLabel(WidgetRef ref, AppRole role) {
    if (FeaturePermission.seesClientPanel(role)) {
      return ProductLabels.clientWorkspace;
    }
    if (!FeaturePermission.seesAdminPanel(role)) {
      return ProductLabels.consultantWorkspace;
    }
    final prefer = ref.watch(preferredConsultantPanelProvider);
    if (prefer == true) return ProductLabels.consultantWorkspace;
    return ProductLabels.managerWorkspace;
  }

  void _goAccountTab(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    ref
        .read(mainShellShortcutProvider.notifier)
        .enqueue(MainShellShortcut.openAccountTab);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    final uid = user?.uid ?? '';
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email ?? 'Hesap');
    final avatarUrl = uid.isEmpty
        ? null
        : ref.watch(
            userDocStreamProvider(uid).select((a) => a.valueOrNull?.avatarUrl));
    final isAdmin = FeaturePermission.seesAdminPanel(role);
    final isClient = FeaturePermission.seesClientPanel(role);
    final versionLabel = AppConstants.appVersion.split('+').first;

    return PremiumScrollableBottomSheetShell(
      showCloseButton: false,
      header: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileAvatar(
                  size: 56,
                  imageUrl: avatarUrl,
                  fallbackText: name,
                ),
                const SizedBox(width: DesignTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: ext.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role.label,
                        style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: ext.background.withValues(alpha: 0.85),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                          border: Border.all(
                              color: ext.border.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ProductLabels.activeView,
                              style: TextStyle(
                                color: ext.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _activePanelLabel(ref, role),
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            const SizedBox(height: DesignTokens.space3),
            _SheetAction(
              icon: Icons.person_outline_rounded,
              label: 'Profili aç',
              onTap: () => _goAccountTab(context, ref),
            ),
            if (!isClient) ...[
              const SizedBox(height: DesignTokens.space2),
              _SheetAction(
                icon: Icons.settings_outlined,
                label: 'Ayarlar',
                onTap: () => _goAccountTab(context, ref),
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(height: DesignTokens.space2),
              _SheetAction(
                icon: Icons.swap_horiz_rounded,
                label: ProductLabels.switchWorkspace,
                subtitle: _activePanelLabel(ref, role),
                onTap: () {
                  Navigator.of(context).pop();
                  _showPanelPickSheet(context, ref);
                },
              ),
            ],
            const SizedBox(height: DesignTokens.space2),
            _SheetAction(
              icon: Icons.notifications_outlined,
              label: 'Bildirimler',
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRouter.routeNotifications);
              },
            ),
            const SizedBox(height: DesignTokens.space2),
            _SheetAction(
              icon: Icons.logout_rounded,
              label: 'Çıkış yap',
              danger: true,
              onTap: () {
                LogoutFlowTracer.step('LOGOUT_FLOW', 'tap account_sheet');
                Navigator.of(context).pop();
                unawaited(
                  AuthLogoutCoordinator.signOut(
                    ref,
                    dismissOverlayFirst: true,
                    source: 'account_sheet',
                  ),
                );
              },
            ),
            const SizedBox(height: DesignTokens.space6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sürüm $versionLabel',
                  style: TextStyle(
                    color: ext.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space3),
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: ext.textTertiary.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const BrandEmblem(
                  variant: BrandEmblemVariant.monoGold,
                  size: 22,
                  opacity: 0.85,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

void _showPanelPickSheet(BuildContext context, WidgetRef ref) {
  final premium = PremiumThemeExtension.of(context);
  final prefer = ref.read(preferredConsultantPanelProvider);
  showPremiumScrollableBottomSheet<void>(
    context: context,
    maxHeightFactor: 0.45,
    builder: (ctx) => PremiumScrollableBottomSheetShell(
      title: 'Panel seçin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            _SheetAction(
              icon: Icons.dashboard_rounded,
              label: ProductLabels.managerWorkspace,
              trailing: prefer != true
                  ? Icon(Icons.check_rounded, color: premium.champagneGold, size: 20)
                  : null,
              onTap: () {
                ref.read(preferredConsultantPanelProvider.notifier).state =
                    false;
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: DesignTokens.space2),
            _SheetAction(
              icon: Icons.person_rounded,
              label: ProductLabels.consultantWorkspace,
              trailing: prefer == true
                  ? Icon(Icons.check_rounded, color: premium.champagneGold, size: 20)
                  : null,
              onTap: () {
                ref.read(preferredConsultantPanelProvider.notifier).state =
                    true;
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
  );
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final fg = danger ? ext.danger : ext.textPrimary;
    final iconColor = danger ? ext.danger : premium.champagneGold;
    return Material(
      color: premium.glassSurface.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: danger
                  ? ext.danger.withValues(alpha: 0.25)
                  : premium.glassBorder.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space4, vertical: DesignTokens.space3),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null)
                Icon(Icons.chevron_right_rounded,
                    color: premium.champagneGoldMuted, size: 22),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
