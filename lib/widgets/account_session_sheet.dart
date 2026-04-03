import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Premium hesap / oturum paneli — ana ekran avatarından.
Future<void> showAccountSessionSheet(BuildContext context, WidgetRef ref) async {
  await HapticFeedback.lightImpact();
  if (!context.mounted) return;
  await showPremiumModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => const _AccountSessionSheet(),
  );
}

class _AccountSessionSheet extends ConsumerWidget {
  const _AccountSessionSheet();

  static String _activePanelLabel(WidgetRef ref, AppRole role) {
    if (FeaturePermission.seesClientPanel(role)) return 'Müşteri deneyimi';
    if (!FeaturePermission.seesAdminPanel(role)) return 'Danışman paneli';
    final prefer = ref.watch(preferredConsultantPanelProvider);
    if (prefer == true) return 'Danışman paneli';
    return 'Yönetici paneli';
  }

  void _goAccountTab(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    ref.read(mainShellShortcutProvider.notifier).state = MainShellShortcut.openAccountTab;
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
        : ref.watch(userDocStreamProvider(uid).select((a) => a.valueOrNull?.avatarUrl));
    final isAdmin = FeaturePermission.seesAdminPanel(role);
    final isClient = FeaturePermission.seesClientPanel(role);
    final versionLabel = AppConstants.appVersion.split('+').first;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space5,
          0,
          DesignTokens.space5,
          DesignTokens.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PremiumBottomSheetHandle(),
            const SizedBox(height: DesignTokens.space2),
            Row(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: ext.background.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          border: Border.all(color: ext.border.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aktif görünüm',
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
            const SizedBox(height: DesignTokens.space5),
            _SheetAction(
              icon: Icons.person_outline_rounded,
              label: 'Profili görüntüle',
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
                label: 'Panel değiştir',
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
                Navigator.of(context).pop();
                AuthService.instance.signOut();
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
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3),
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
      ),
    );
  }
}

void _showPanelPickSheet(BuildContext context, WidgetRef ref) {
  final ext = AppThemeExtension.of(context);
  final prefer = ref.read(preferredConsultantPanelProvider);
  showPremiumModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space5,
          0,
          DesignTokens.space5,
          DesignTokens.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PremiumBottomSheetHandle(),
            const SizedBox(height: DesignTokens.space3),
            Text(
              'Panel seçin',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: DesignTokens.space4),
            _SheetAction(
              icon: Icons.dashboard_rounded,
              label: 'Yönetici paneli',
              trailing: prefer != true ? Icon(Icons.check_rounded, color: ext.accent, size: 20) : null,
              onTap: () {
                ref.read(preferredConsultantPanelProvider.notifier).state = false;
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: DesignTokens.space2),
            _SheetAction(
              icon: Icons.person_rounded,
              label: 'Danışman paneli',
              trailing: prefer == true ? Icon(Icons.check_rounded, color: ext.accent, size: 20) : null,
              onTap: () {
                ref.read(preferredConsultantPanelProvider.notifier).state = true;
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
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
    final fg = danger ? ext.danger : ext.textPrimary;
    final iconColor = danger ? ext.danger : ext.accent;
    return Material(
      color: ext.surfaceElevated.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space3),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
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
                Icon(Icons.chevron_right_rounded, color: ext.textTertiary.withValues(alpha: 0.65), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
