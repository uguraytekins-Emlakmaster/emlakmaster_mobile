import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_color_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_shadow_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/consultant_dashboard_tokens.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/screens/providers/consultant_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Unified executive KPI cockpit — luxury depth, sparkline fill, storytelling.
class ConsultantDashboardKpiBento extends ConsumerWidget {
  const ConsultantDashboardKpiBento({super.key});

  static const int weeklyCallGoal = 15;

  static List<double> weekMomentumSparkline(int weeklyTotal) {
    if (weeklyTotal <= 0) return const [0.15, 0.35, 0.55, 0.72, 0.85, 0.92, 1.0];
    final day = DateTime.now().weekday.clamp(1, 7);
    return List.generate(7, (i) {
      final d = i + 1;
      if (d <= day) return weeklyTotal * (d / day);
      return weeklyTotal.toDouble();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(
      currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''),
    );

    void openCalls() {
      AppFeedback.lightImpact();
      context.push(AppRouter.routeConsultantCalls);
    }

    void openTasks() {
      AppFeedback.lightImpact();
      ref
          .read(mainShellShortcutProvider.notifier)
          .enqueue(MainShellShortcut.openTasksTab);
      context.go(AppRouter.routeHome);
    }

    void openPipeline() {
      AppFeedback.lightImpact();
      context.push(AppRouter.routePipeline);
    }

    final compact = MediaQuery.sizeOf(context).width < 340;

    return ConsultantDashboardExecutiveSurface(
      goldBorder: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _CallsKpiCell(
                uid: uid,
                onTap: openCalls,
                compact: compact,
              ),
            ),
            _KpiDivider(),
            Expanded(
              child: _TasksKpiCell(
                uid: uid,
                onTap: openTasks,
                compact: compact,
              ),
            ),
            _KpiDivider(),
            Expanded(
              child: _PipelineKpiCell(
                uid: uid,
                onTap: openPipeline,
                compact: compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: premium.champagneGold.withValues(alpha: 0.22),
    );
  }
}

class _CallsKpiCell extends ConsumerWidget {
  const _CallsKpiCell({
    required this.uid,
    required this.onTap,
    this.compact = false,
  });

  final String uid;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final premium = PremiumThemeExtension.of(context);
    final today =
        ref.watch(todayCallsCountProvider.select((a) => a.valueOrNull ?? 0));
    final weekly = uid.isEmpty
        ? 0
        : ref.watch(
            agentWeeklyCallCountProvider(uid)
                .select((a) => a.valueOrNull ?? 0),
          );
    final trend = weekly >= ConsultantDashboardKpiBento.weeklyCallGoal
        ? 'Hedef ✓'
        : '+$today bugün';
    return _ExecutiveKpiCell(
      icon: Icons.phone_in_talk_rounded,
      value: '$today',
      label: l10n.t('today_calls'),
      story: compact
          ? '$weekly/${ConsultantDashboardKpiBento.weeklyCallGoal} hafta'
          : '$weekly/${ConsultantDashboardKpiBento.weeklyCallGoal} haftalık tempo',
      trendLabel: trend,
      trendUp: today > 0 || weekly >= ConsultantDashboardKpiBento.weeklyCallGoal,
      sparkline: ConsultantDashboardKpiBento.weekMomentumSparkline(weekly),
      accent: premium.champagneGold,
      emphasized: true,
      compact: compact,
      onTap: onTap,
    );
  }
}

class _TasksKpiCell extends ConsumerWidget {
  const _TasksKpiCell({
    required this.uid,
    required this.onTap,
    this.compact = false,
  });

  final String uid;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final premium = PremiumThemeExtension.of(context);
    final count = uid.isEmpty
        ? 0
        : ref.watch(
            advisorOpenTasksCountProvider(uid)
                .select((a) => a.valueOrNull ?? 0),
          );
    return _ExecutiveKpiCell(
      icon: Icons.task_alt_rounded,
      value: '$count',
      label: l10n.t('open_tasks'),
      story: count == 0 ? 'Temiz slate' : (compact ? 'Kuyruk' : 'Aksiyon kuyruğu'),
      trendLabel: count > 0 ? 'Öncelik' : 'Hazır',
      trendUp: count > 0,
      accent: premium.champagneGoldMuted,
      compact: compact,
      onTap: onTap,
    );
  }
}

class _PipelineKpiCell extends ConsumerWidget {
  const _PipelineKpiCell({
    required this.uid,
    required this.onTap,
    this.compact = false,
  });

  final String uid;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final premium = PremiumThemeExtension.of(context);
    final count = uid.isEmpty
        ? 0
        : ref.watch(
            advisorPipelineCountProvider(uid)
                .select((a) => a.valueOrNull ?? 0),
          );
    return _ExecutiveKpiCell(
      icon: Icons.account_tree_rounded,
      value: '$count',
      label: l10n.t('active_pipeline'),
      story: count == 0 ? 'Fırsat ekle' : (compact ? 'Canlı hat' : 'Satış hattı canlı'),
      trendLabel: count > 0 ? 'Canlı' : null,
      trendUp: count > 0,
      accent: premium.champagneGold,
      compact: compact,
      onTap: onTap,
    );
  }
}

class _ExecutiveKpiCell extends StatelessWidget {
  const _ExecutiveKpiCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.story,
    required this.accent,
    required this.onTap,
    this.trendLabel,
    this.trendUp,
    this.sparkline,
    this.emphasized = false,
    this.compact = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final String story;
  final Color accent;
  final VoidCallback onTap;
  final String? trendLabel;
  final bool? trendUp;
  final List<double>? sparkline;
  final bool emphasized;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
  final premium = PremiumThemeExtension.of(context);
    final cellPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 7, vertical: 9)
        : ConsultantDashboardTokens.kpiCellPadding;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: cellPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.32),
                      ),
                      boxShadow: emphasized
                          ? PremiumShadowTokens.kpiCellGlow(accent)
                          : null,
                    ),
                    child: Icon(icon, size: 13, color: accent),
                  ),
                  const Spacer(),
                  if (trendLabel != null)
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _TrendPill(label: trendLabel!, up: trendUp),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ShaderMask(
                shaderCallback: emphasized
                    ? (bounds) => LinearGradient(
                          colors: [
                            PremiumColorTokens.champagneGoldLight,
                            premium.champagneGold,
                          ],
                        ).createShader(bounds)
                    : (bounds) => LinearGradient(
                          colors: [ext.textPrimary, ext.textPrimary],
                        ).createShader(bounds),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.metricValue(context).copyWith(
                      fontSize: emphasized
                          ? 24
                          : ConsultantDashboardTokens.kpiValueSize,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -0.6,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: 0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                story,
                style: TextStyle(
                  color: ext.textTertiary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sparkline != null && sparkline!.length >= 2) ...[
                const SizedBox(height: 6),
                PremiumSparkline(
                  values: sparkline!,
                  color: accent,
                  strokeWidth: 2,
                  showFill: true,
                  showGrid: emphasized,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.label, this.up});

  final String label;
  final bool? up;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = up == true
        ? ext.success
        : (up == false ? ext.textTertiary : ext.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
