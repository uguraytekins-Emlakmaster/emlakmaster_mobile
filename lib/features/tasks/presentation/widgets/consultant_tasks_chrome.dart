import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/consultant_tasks_tokens.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

/// Görevlerim — kompakt executive başlık.
class PremiumTasksPageHeader extends StatelessWidget {
  const PremiumTasksPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.compact = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tight = compact;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ConsultantTasksTokens.horizontal,
        tight ? ConsultantTasksTokens.topInset + 4 : DesignTokens.space3,
        ConsultantTasksTokens.horizontal,
        tight
            ? ConsultantTasksTokens.headerBottomGap
            : ConsultantTasksTokens.chromeGap,
      ),
      child: Row(
        children: [
          BrandEmblem(
            variant: BrandEmblemVariant.mini,
            size: tight
                ? ConsultantTasksTokens.headerEmblemSize
                : 40,
          ),
          SizedBox(width: tight ? 8 : DesignTokens.space2 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.pageHeading(context).copyWith(
                    fontSize: tight
                        ? ConsultantTasksTokens.headerTitleSize
                        : DesignTokens.fontSize2xl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.05,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tight ? 2 : 4),
                Text(
                  subtitle,
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textSecondary.withValues(alpha: 0.88),
                    fontSize: tight
                        ? ConsultantTasksTokens.headerSubtitleSize
                        : DesignTokens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Gerçek görev özet şeridi — sahte KPI yok.
class PremiumTasksSummaryStrip extends StatelessWidget {
  const PremiumTasksSummaryStrip({
    super.key,
    required this.summary,
  });

  final TaskListSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = [
      (summary.open.toString(), 'Açık', ext.accent),
      (summary.today.toString(), 'Bugün', ext.warning),
      (summary.overdue.toString(), 'Geciken', ext.danger),
      (summary.upcoming.toString(), 'Yaklaşan', ext.info),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantTasksTokens.horizontal,
        ConsultantTasksTokens.chromeGap / 2,
        ConsultantTasksTokens.horizontal,
        ConsultantTasksTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        child: SizedBox(
          height: ConsultantTasksTokens.summaryStripHeight - 16,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: ext.border.withValues(alpha: 0.35),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cells[i].$1,
                        style: AppTypography.metricValue(context).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cells[i].$3,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cells[i].$2,
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumTaskFilterStrip extends StatelessWidget {
  const PremiumTaskFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TaskListFilter selected;
  final ValueChanged<TaskListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantTasksTokens.horizontal,
        0,
        ConsultantTasksTokens.horizontal,
        ConsultantTasksTokens.sectionGap,
      ),
      child: SizedBox(
        height: ConsultantTasksTokens.filterStripHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: TaskListFilter.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final filter = TaskListFilter.values[index];
            return PremiumFilterChip(
              label: filter.label,
              selected: selected == filter,
              onTap: () => onSelected(filter),
            );
          },
        ),
      ),
    );
  }
}
