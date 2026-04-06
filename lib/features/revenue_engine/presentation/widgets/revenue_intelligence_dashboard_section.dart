import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/providers/usage_providers.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/pro_blur_overlay_gate.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Gelir motoru özeti: sıcak müşteriler, bugün aksiyon, risk, performans.
class RevenueIntelligenceDashboardSection extends ConsumerWidget {
  const RevenueIntelligenceDashboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final full = ref.watch(revenueDashboardSnapshotProvider);
    final blurLocked = ref.watch(shouldBlurRevenueInsightsProvider);
    if (full.hotCustomers.isEmpty &&
        full.actionToday.isEmpty &&
        full.atRiskSync.isEmpty &&
        full.selfPerformanceScore == 0) {
      return const SizedBox.shrink();
    }

    final ext = AppThemeExtension.of(context);

    return ProBlurOverlayGate(
      locked: blurLocked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gelir motoru',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ext.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _MiniRow(
            icon: Icons.local_fire_department_outlined,
            iconColor: ext.warning,
            title: '🔥 Sıcak müşteriler',
            subtitle: full.hotCustomers.isEmpty
                ? 'Şu an sıcak skorlu müşteri yok'
                : full.hotCustomers
                    .map((e) => e.displayName)
                    .take(3)
                    .join(', '),
            count: full.hotCustomers.length,
            onTap: () => ConsultantShellNav.goToCustomersTab(context),
          ),
          const SizedBox(height: 6),
          _MiniRow(
            icon: Icons.phone_callback_outlined,
            iconColor: ext.accent,
            title: '📞 Bugün aksiyon',
            subtitle: full.actionToday.isEmpty
                ? 'Bugün için planlı hatırlatma yok'
                : full.actionToday.map((e) => e.displayName).take(3).join(', '),
            count: full.actionToday.length,
            onTap: () => ConsultantShellNav.goToCustomersTab(context),
          ),
          const SizedBox(height: 6),
          _MiniRow(
            icon: Icons.sync_problem_outlined,
            iconColor: ext.textSecondary,
            title: '⏳ Senkron / veri riski',
            subtitle: full.atRiskSync.isEmpty
                ? 'Geciken senkron uyarısı yok'
                : full.atRiskSync.map((e) => e.displayName).take(3).join(', '),
            count: full.atRiskSync.length,
            onTap: () => ConsultantShellNav.goToCustomersTab(context),
          ),
          const SizedBox(height: 6),
          _MiniRow(
            icon: Icons.emoji_events_outlined,
            iconColor: ext.success,
            title: '🏆 Performans puanın',
            subtitle: full.leaderboard.isEmpty
                ? '—'
                : '${full.leaderboard.first.displayLabel}: ${full.selfPerformanceScore}',
            onTap: () => context.push(AppRouter.routeConsultantCalls),
          ),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surfaceElevated,
      borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space2,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: ext.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (count != null && count! > 0)
                          Text(
                            '$count',
                            style: TextStyle(
                              color: ext.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ext.textTertiary,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: ext.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
