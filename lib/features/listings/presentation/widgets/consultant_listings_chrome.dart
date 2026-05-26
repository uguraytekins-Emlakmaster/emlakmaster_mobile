import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/consultant_listings_tokens.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

/// İlanlarım — kompakt executive başlık.
class PremiumListingsPageHeader extends StatelessWidget {
  const PremiumListingsPageHeader({
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
    final tight = compact;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ConsultantListingsTokens.horizontal,
        tight ? ConsultantListingsTokens.topInset + 4 : DesignTokens.space3,
        ConsultantListingsTokens.horizontal,
        tight
            ? ConsultantListingsTokens.headerBottomGap
            : ConsultantListingsTokens.chromeGap,
      ),
      child: Row(
        children: [
          BrandEmblem(
            variant: BrandEmblemVariant.mini,
            size: tight
                ? ConsultantListingsTokens.headerEmblemSize
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
                        ? ConsultantListingsTokens.headerTitleSize
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
                    color: AppThemeExtension.of(context)
                        .textSecondary
                        .withValues(alpha: 0.88),
                    fontSize: tight
                        ? ConsultantListingsTokens.headerSubtitleSize
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

/// Gerçek portföy sayımları.
class PremiumListingsSummaryStrip extends StatelessWidget {
  const PremiumListingsSummaryStrip({
    super.key,
    required this.summary,
  });

  final ListingListSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      (summary.active.toString(), 'Aktif', ext.success),
      (summary.draft.toString(), 'Taslak', ext.info),
      (summary.published.toString(), 'Yayında', ext.accent),
      (summary.attention.toString(), 'Dikkat', ext.warning),
      (summary.total.toString(), 'Toplam', ext.textSecondary),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantListingsTokens.horizontal,
        ConsultantListingsTokens.chromeGap / 2,
        ConsultantListingsTokens.horizontal,
        ConsultantListingsTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SizedBox(
          height: ConsultantListingsTokens.summaryStripHeight - 16,
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

class PremiumListingSearchRow extends StatelessWidget {
  const PremiumListingSearchRow({
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
        ConsultantListingsTokens.horizontal,
        0,
        ConsultantListingsTokens.horizontal,
        ConsultantListingsTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SizedBox(
          height: ConsultantListingsTokens.searchBarHeight,
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

class PremiumListingFilterStrip extends StatelessWidget {
  const PremiumListingFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ListingListFilter selected;
  final ValueChanged<ListingListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantListingsTokens.horizontal,
        0,
        ConsultantListingsTokens.horizontal,
        ConsultantListingsTokens.sectionGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ClipRect(
          child: SizedBox(
          height: ConsultantListingsTokens.filterStripHeight,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              overscroll: false,
            ),
            child: ListView.separated(
              key: const Key('listing_filter_strip_scroll'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              clipBehavior: Clip.none,
              cacheExtent: 320,
              padding: const EdgeInsets.only(right: 4),
              itemCount: ListingListFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final filter = ListingListFilter.values[index];
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
