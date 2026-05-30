import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/services/auth_logout_coordinator.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/listing_display/presentation/widgets/listing_display_settings_section.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/widgets/notifications_settings_section.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/test_role_switch_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomersPlaceholderPage extends StatelessWidget {
  const CustomersPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = AppThemeExtension.of(context).background;
    return Scaffold(
      backgroundColor: bg,
      body: const SafeArea(
        child: EmptyState(
          grouped: true,
          premiumVisual: true,
          icon: Icons.people_outline_rounded,
          title: 'Müşteriler',
          subtitle:
              'Kartlar, görüşmeler ve görevler ana akıştan açılır; kayıtlarınız burada toplanır.',
        ),
      ),
    );
  }
}

class SettingsPlaceholderPage extends ConsumerWidget {
  const SettingsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    final realRole = ref.watch(currentRoleOrNullProvider) ?? AppRole.guest;
    final canSwitchRole = kDebugMode &&
        (realRole == AppRole.superAdmin || realRole == AppRole.brokerOwner);
    final override = ref.watch(overrideRoleProvider);
    final preferConsultant = ref.watch(preferredConsultantPanelProvider);
    final isAdmin = FeaturePermission.seesAdminPanel(realRole);
    final canBecomeAdmin = user != null &&
        (realRole == AppRole.agent || realRole == AppRole.guest);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppThemeExtension.of(context).background
        : AppThemeExtension.of(context).background;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = onSurface.withValues(alpha: 0.7);
    return Scaffold(
      backgroundColor: bg,
      appBar: emlakAppBar(
        context,
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? onSurface,
        title: const Text('Ayarlar'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Görünüm',
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const ThemeSection(),
            const SizedBox(height: 24),
            Text(
              'Bildirimler',
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const NotificationsSection(),
            const SizedBox(height: 24),
            const ListingDisplaySettingsSection(),
            const SizedBox(height: 24),
            if (user != null) ...[
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                title: Text(
                  user.email ?? 'Giriş yapılmış',
                  style:
                      TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Rol: ${override?.label ?? role.label}',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (canBecomeAdmin) ...[
              Text(
                'Yetki',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.admin_panel_settings_rounded,
                    color: AppThemeExtension.of(context).accent),
                title: Text(
                  'Yönetim yetkisini aç',
                  style: TextStyle(color: onSurface),
                ),
                subtitle: Text(
                  'Rolünüz yönetim alanını açacak şekilde güncellenir; yönetim ve danışman görünümleri arasında geçebilirsiniz.',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 11),
                ),
                onTap: () async {
                  final u = user;
                  try {
                    await UserRepository.setUserDoc(
                      uid: u.uid,
                      role: 'broker_owner',
                      name: u.displayName,
                      email: u.email,
                    );
                    ref.invalidate(userDocStreamProvider(u.uid));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Yönetim yetkisi açıldı. Alan yenileniyor...'),
                          backgroundColor: AppThemeExtension.of(context).accent,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
            if (isAdmin) ...[
              Text(
                'Panel görünümü',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.dashboard_rounded,
                  color: preferConsultant != true
                      ? AppThemeExtension.of(context).accent
                      : onSurfaceVariant,
                ),
                title: Text(ProductLabels.managerWorkspace,
                    style: TextStyle(color: onSurface)),
                subtitle: Text(
                  '${ProductLabels.managerHome}, ${ProductLabels.warRoom}, ${ProductLabels.callCenter}, Ekonomi, ${ProductLabels.reports} ve Kadro',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 11),
                ),
                trailing: preferConsultant != true
                    ? Icon(Icons.check_rounded,
                        color: AppThemeExtension.of(context).accent)
                    : null,
                onTap: () {
                  ref.read(preferredConsultantPanelProvider.notifier).state =
                      false;
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.person_rounded,
                  color: preferConsultant == true
                      ? AppThemeExtension.of(context).accent
                      : onSurfaceVariant,
                ),
                title: Text(ProductLabels.consultantWorkspace,
                    style: TextStyle(color: onSurface)),
                subtitle: Text(
                  '${ProductLabels.consultantHome}, ${ProductLabels.myCustomers}, ${ProductLabels.listings}, ${ProductLabels.followUp}, ${ProductLabels.myCalls}',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 11),
                ),
                trailing: preferConsultant == true
                    ? Icon(Icons.check_rounded,
                        color: AppThemeExtension.of(context).accent)
                    : null,
                onTap: () {
                  ref.read(preferredConsultantPanelProvider.notifier).state =
                      true;
                },
              ),
              const SizedBox(height: 24),
            ],
            if (canSwitchRole) ...[
              Text(
                'Yönetici test',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.swap_horiz_rounded,
                    color: AppThemeExtension.of(context).accent),
                title: Text(
                  override != null
                      ? 'Rol: ${override.label} (geri al)'
                      : 'Rol değiştir (test)',
                  style: TextStyle(color: onSurface),
                ),
                onTap: () => _showRoleSwitcher(context, ref, override),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Hesap',
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.logout_rounded,
                  color: AppThemeExtension.of(context).danger),
              title: Text('Çıkış yap', style: TextStyle(color: onSurface)),
              onTap: () async {
                await AuthLogoutCoordinator.signOut(ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleSwitcher(
      BuildContext context, WidgetRef ref, AppRole? currentOverride) {
    showTestRoleSwitchSheet(context, ref, currentOverride);
  }
}

class ThemeSection extends ConsumerWidget {
  const ThemeSection({super.key, this.embedInParentCard = false});

  /// [true]: yalnızca satır; üst kart [SettingsPage._sectionCard] tarafından verilir.
  final bool embedInParentCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark
        ? AppThemeExtension.of(context).card
        : AppThemeExtension.of(context).surface;
    final border = isDark
        ? AppThemeExtension.of(context).border.withValues(alpha: 0.5)
        : AppThemeExtension.of(context).border;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = onSurface.withValues(alpha: 0.7);
    final index = ref.watch(themeModeIndexProvider);
    final tile = ListTile(
      leading: Icon(
        index == 0
            ? Icons.brightness_auto_rounded
            : (index == 1 ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
        color: AppThemeExtension.of(context).accent,
      ),
      title: Text('Tema', style: TextStyle(color: onSurface)),
      subtitle: Text(
        index == 0 ? 'Sistem' : (index == 1 ? 'Açık' : 'Koyu'),
        style: TextStyle(color: onSurfaceVariant, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
      onTap: () =>
          ThemeSection._showThemePicker(context, ref, currentIndex: index),
    );
    if (embedInParentCard) return tile;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [tile],
      ),
    );
  }

  static void _showThemePicker(BuildContext context, WidgetRef ref,
      {required int currentIndex}) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    showPremiumModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumBottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space2,
                DesignTokens.space4,
                DesignTokens.space3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: DesignTokens.iconLg,
                    color: ext.accent.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                  const Expanded(
                    child: PremiumSheetHeader(
                      compact: true,
                      title: 'Tema',
                      subtitle: 'Sistem, açık veya koyu',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    style: IconButton.styleFrom(
                      foregroundColor: ext.textTertiary,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space5,
              ),
              leading: Icon(
                Icons.brightness_auto_outlined,
                color: ext.textSecondary,
                size: DesignTokens.iconMd,
              ),
              title: Text('Sistem', style: TextStyle(color: textColor)),
              trailing: currentIndex == 0
                  ? Icon(Icons.check_rounded,
                      color: ext.accent, size: DesignTokens.iconMd)
                  : null,
              onTap: () {
                ref.read(themeModeIndexProvider.notifier).setThemeModeIndex(0);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space5,
              ),
              leading: Icon(
                Icons.light_mode_outlined,
                color: ext.textSecondary,
                size: DesignTokens.iconMd,
              ),
              title: Text('Açık', style: TextStyle(color: textColor)),
              trailing: currentIndex == 1
                  ? Icon(Icons.check_rounded,
                      color: ext.accent, size: DesignTokens.iconMd)
                  : null,
              onTap: () {
                ref.read(themeModeIndexProvider.notifier).setThemeModeIndex(1);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space5,
              ),
              leading: Icon(
                Icons.dark_mode_outlined,
                color: ext.textSecondary,
                size: DesignTokens.iconMd,
              ),
              title: Text('Koyu', style: TextStyle(color: textColor)),
              trailing: currentIndex == 2
                  ? Icon(Icons.check_rounded,
                      color: ext.accent, size: DesignTokens.iconMd)
                  : null,
              onTap: () {
                ref.read(themeModeIndexProvider.notifier).setThemeModeIndex(2);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: DesignTokens.space4),
          ],
        ),
      ),
    );
  }
}

/// Geriye dönük: ayarlar hub'ı [NotificationsSettingsSection] kullanır.
class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key, this.embedInParentCard = false});

  final bool embedInParentCard;

  @override
  Widget build(BuildContext context) {
    return NotificationsSettingsSection(embedInParentCard: embedInParentCard);
  }
}
