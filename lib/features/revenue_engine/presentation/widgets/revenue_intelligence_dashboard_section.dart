import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
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
    final ext = AppThemeExtension.of(context);
    final allQuiet = full.hotCustomers.isEmpty &&
        full.actionToday.isEmpty &&
        full.atRiskSync.isEmpty &&
        full.selfPerformanceScore == 0;

    if (allQuiet) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.space5),
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.55),
          borderRadius:
              BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
          border: Border.all(color: ext.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_outlined, color: ext.accent, size: 22),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gelir motoru — kontrol tamam',
                    style: AppTypography.cardHeading(context),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'Sistem baktı: sıcak alarm, bugünkü hatırlatma veya senkron riski yok. '
                    'Yeni sinyaller oluşunca burada öne çıkar; şimdilik odak çağrı ve portföyde.',
                    style: AppTypography.body(context).copyWith(
                      color: ext.textTertiary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gelir motoru',
          style: AppTypography.cardHeading(context)
              .copyWith(color: ext.textSecondary),
        ),
        const SizedBox(height: DesignTokens.sectionTitleGap),
        _MiniRow(
          icon: Icons.local_fire_department_outlined,
          iconColor: ext.warning,
          title: 'Sıcak müşteriler',
          subtitle: full.hotCustomers.isEmpty
              ? 'Öncelikli sıcak skor yok — portföyün dengede'
              : full.hotCustomers.map((e) => e.displayName).take(3).join(', '),
          count: full.hotCustomers.length,
          onTap: () => ConsultantShellNav.goToCustomersTab(context),
          relaxed: full.hotCustomers.isEmpty,
        ),
        const SizedBox(height: DesignTokens.space2),
        _MiniRow(
          icon: Icons.phone_callback_outlined,
          iconColor: ext.accent,
          title: 'Bugün aksiyon',
          subtitle: full.actionToday.isEmpty
              ? 'Planlı hatırlatma yok — günü çağrıyla doldurabilirsin'
              : full.actionToday.map((e) => e.displayName).take(3).join(', '),
          count: full.actionToday.length,
          onTap: () => ConsultantShellNav.goToCustomersTab(context),
          relaxed: full.actionToday.isEmpty,
        ),
        const SizedBox(height: DesignTokens.space2),
        _MiniRow(
          icon: Icons.sync_problem_outlined,
          iconColor: ext.textSecondary,
          title: 'Senkron / veri riski',
          subtitle: full.atRiskSync.isEmpty
              ? 'Geciken senkron uyarısı yok'
              : full.atRiskSync.map((e) => e.displayName).take(3).join(', '),
          count: full.atRiskSync.length,
          onTap: () => ConsultantShellNav.goToCustomersTab(context),
          relaxed: full.atRiskSync.isEmpty,
        ),
        const SizedBox(height: DesignTokens.space2),
        _MiniRow(
          icon: Icons.emoji_events_outlined,
          iconColor: ext.success,
          title: 'Liderlik görünümü',
          subtitle: full.leaderboard.isEmpty
              ? 'Skorun oluşunca tablo burada netleşir'
              : '${full.leaderboard.first.displayLabel}: ${full.selfPerformanceScore}',
          onTap: () => context.push(AppRouter.routeConsultantCalls),
          relaxed: full.leaderboard.isEmpty,
        ),
      ],
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
    this.relaxed = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? count;
  final bool relaxed;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final bg = relaxed
        ? ext.surface.withValues(alpha: 0.45)
        : ext.surfaceElevated;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
        splashColor: ext.accent.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3 + 1,
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
                            style: AppTypography.cardHeading(context)
                                .copyWith(
                              fontSize: DesignTokens.fontSizeMd,
                              fontWeight:
                                  relaxed ? FontWeight.w600 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (count != null && count! > 0)
                          Text(
                            '$count',
                            style: AppTypography.metricLabel(context)
                                .copyWith(color: ext.accent),
                          ),
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.meta(context).copyWith(
                        color: relaxed ? ext.textTertiary : null,
                        height: 1.35,
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
