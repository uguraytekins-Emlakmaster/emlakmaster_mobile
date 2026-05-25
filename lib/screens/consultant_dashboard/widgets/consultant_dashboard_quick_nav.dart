import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Executive quick-access dock — premium glass row.
class ConsultantDashboardQuickNavGrid extends ConsumerWidget {
  const ConsultantDashboardQuickNavGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goTab(MainShellShortcut shortcut) {
      AppFeedback.selectionClick();
      ref.read(mainShellShortcutProvider.notifier).enqueue(shortcut);
      context.go(AppRouter.routeHome);
    }

    return ConsultantDashboardExecutiveSurface(
      goldBorder: true,
      child: IntrinsicHeight(
        child: Row(
          children: [
            ConsultantDashboardQuickNavTile(
              icon: Icons.people_alt_rounded,
              label: ProductLabels.myCustomers,
              onTap: () => goTab(MainShellShortcut.openCustomersTab),
            ),
            _NavDivider(),
            ConsultantDashboardQuickNavTile(
              icon: Icons.task_alt_rounded,
              label: ProductLabels.myTasks,
              onTap: () => goTab(MainShellShortcut.openTasksTab),
            ),
            _NavDivider(),
            ConsultantDashboardQuickNavTile(
              icon: Icons.home_work_outlined,
              label: ProductLabels.listings,
              onTap: () => goTab(MainShellShortcut.openListingsTab),
            ),
            _NavDivider(),
            ConsultantDashboardQuickNavTile(
              icon: Icons.forum_outlined,
              label: ProductLabels.messageCenter,
              onTap: () => goTab(MainShellShortcut.openMessageCenterTab),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: premium.champagneGold.withValues(alpha: 0.14),
    );
  }
}

class ConsultantDashboardQuickNavTile extends StatelessWidget {
  const ConsultantDashboardQuickNavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    final ext = AppThemeExtension.of(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        premium.champagneGold.withValues(alpha: 0.16),
                        premium.champagneGold.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: premium.champagneGold.withValues(alpha: 0.32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: premium.champagneGold.withValues(alpha: 0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: premium.champagneGold, size: 15),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
