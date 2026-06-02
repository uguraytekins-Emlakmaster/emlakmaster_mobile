import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/widgets/notifications_settings_section.dart';
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
