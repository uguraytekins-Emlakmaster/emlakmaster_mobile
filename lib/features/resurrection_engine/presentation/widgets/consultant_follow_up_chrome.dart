import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/consultant_follow_up_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_filter.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

class PremiumFollowUpPageHeader extends StatelessWidget {
  const PremiumFollowUpPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.topInset + 4,
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandEmblem(
                variant: BrandEmblemVariant.mini,
                size: ConsultantFollowUpTokens.headerEmblemSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.pageHeading(context).copyWith(
                        fontSize: ConsultantFollowUpTokens.headerTitleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.05,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.meta(context).copyWith(
                        color: ext.textSecondary.withValues(alpha: 0.88),
                        fontSize: ConsultantFollowUpTokens.headerSubtitleSize,
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
          const SizedBox(height: 4),
          Text(
            'Öncelik: kural tabanlı CRM sıcaklığı · LLM skoru yok',
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class PremiumFollowUpSummaryStrip extends StatelessWidget {
  const PremiumFollowUpSummaryStrip({super.key, required this.summary});

  final FollowUpListSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      (summary.todayFollowUp.toString(), 'Bugün takip', ext.accent),
      (summary.overdue.toString(), 'Geciken', ext.warning),
      (summary.callback.toString(), 'Geri aranacak', ext.info),
      (summary.coldLeads.toString(), 'Soğuk lead', ext.textSecondary),
      (summary.opportunity.toString(), 'Fırsat', ext.success),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.chromeGap / 2,
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SizedBox(
          height: ConsultantFollowUpTokens.summaryStripHeight - 16,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: ext.border.withValues(alpha: 0.35),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cells[i].$1,
                        style: AppTypography.metricValue(context).copyWith(
                          fontSize: 14,
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
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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

class PremiumFollowUpSearchRow extends StatelessWidget {
  const PremiumFollowUpSearchRow({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantFollowUpTokens.horizontal,
        0,
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SizedBox(
          height: ConsultantFollowUpTokens.searchBarHeight,
          child: PremiumSearchBar(
            controller: controller,
            hintText: hintText,
            compact: true,
          ),
        ),
      ),
    );
  }
}

class PremiumFollowUpFilterStrip extends StatelessWidget {
  const PremiumFollowUpFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FollowUpListFilter selected;
  final ValueChanged<FollowUpListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantFollowUpTokens.horizontal,
        0,
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.sectionGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ClipRect(
          child: SizedBox(
            height: ConsultantFollowUpTokens.filterStripHeight,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
                overscroll: false,
              ),
              child: ListView.separated(
                key: const Key('follow_up_filter_strip_scroll'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                clipBehavior: Clip.none,
                cacheExtent: 360,
                padding: const EdgeInsets.only(right: 4),
                itemCount: FollowUpListFilter.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final filter = FollowUpListFilter.values[index];
                  return PremiumFilterChip(
                    label: filter.label,
                    selected: selected == filter,
                    onTap: () => onSelected(filter),
                    dense: true,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
