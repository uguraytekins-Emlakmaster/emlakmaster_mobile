import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 2×2 shortcut grid — müşteri, görev, ilan, mesaj.
class ConsultantDashboardQuickNavGrid extends ConsumerWidget {
  const ConsultantDashboardQuickNavGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goTab(MainShellShortcut shortcut) {
      AppFeedback.selectionClick();
      ref.read(mainShellShortcutProvider.notifier).enqueue(shortcut);
      context.go(AppRouter.routeHome);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - DesignTokens.space2) / 2;
        return Wrap(
          spacing: DesignTokens.space2,
          runSpacing: DesignTokens.space2,
          children: [
            ConsultantDashboardQuickNavTile(
              width: cellW,
              icon: Icons.people_rounded,
              label: ProductLabels.myCustomers,
              onTap: () => goTab(MainShellShortcut.openCustomersTab),
            ),
            ConsultantDashboardQuickNavTile(
              width: cellW,
              icon: Icons.task_alt_rounded,
              label: ProductLabels.myTasks,
              onTap: () => goTab(MainShellShortcut.openTasksTab),
            ),
            ConsultantDashboardQuickNavTile(
              width: cellW,
              icon: Icons.home_work_rounded,
              label: ProductLabels.listings,
              onTap: () => goTab(MainShellShortcut.openListingsTab),
            ),
            ConsultantDashboardQuickNavTile(
              width: cellW,
              icon: Icons.forum_rounded,
              label: ProductLabels.messageCenter,
              onTap: () => goTab(MainShellShortcut.openMessageCenterTab),
            ),
          ],
        );
      },
    );
  }
}

class ConsultantDashboardQuickNavTile extends StatelessWidget {
  const ConsultantDashboardQuickNavTile({
    super.key,
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      width: width,
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space4,
        ),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: premium.champagneGold.withValues(alpha: 0.12),
                border: Border.all(
                  color: premium.champagneGold.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(icon, color: premium.champagneGold, size: 22),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ext.textPrimary,
                fontSize: DesignTokens.fontSizeXs,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
