import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/consultant_integrations_tokens.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/utils/integration_center_filter.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

class PremiumIntegrationsPageHeader extends StatelessWidget {
  const PremiumIntegrationsPageHeader({
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
        ConsultantIntegrationsTokens.horizontal,
        ConsultantIntegrationsTokens.topInset + 4,
        ConsultantIntegrationsTokens.horizontal,
        ConsultantIntegrationsTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandEmblem(
                variant: BrandEmblemVariant.mini,
                size: ConsultantIntegrationsTokens.headerEmblemSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.pageHeading(context).copyWith(
                        fontSize: ConsultantIntegrationsTokens.headerTitleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.meta(context).copyWith(
                        color: ext.textSecondary.withValues(alpha: 0.88),
                        fontSize:
                            ConsultantIntegrationsTokens.headerSubtitleSize,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ext.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.info.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Doğrulama notu: yalnızca gerçek bağlantı durumları gösterilir.',
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumIntegrationsSummaryStrip extends StatelessWidget {
  const PremiumIntegrationsSummaryStrip({super.key, required this.summary});

  final IntegrationCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      (summary.connectedAccounts.toString(), 'Bağlı', ext.success),
      (summary.setupRequired.toString(), 'Kurulum', ext.warning),
      (summary.previewOnly.toString(), 'Önizleme', ext.info),
      (summary.adminRequired.toString(), 'Admin', ext.danger),
      (summary.syncSupported.toString(), 'Senkron', ext.accent),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantIntegrationsTokens.horizontal,
        ConsultantIntegrationsTokens.chromeGap / 2,
        ConsultantIntegrationsTokens.horizontal,
        ConsultantIntegrationsTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SizedBox(
          height: ConsultantIntegrationsTokens.summaryStripHeight - 16,
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: cells[i].$3,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cells[i].$2,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontSize: 8.8,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
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

class PremiumIntegrationsSearchRow extends StatelessWidget {
  const PremiumIntegrationsSearchRow({
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
        ConsultantIntegrationsTokens.horizontal,
        0,
        ConsultantIntegrationsTokens.horizontal,
        ConsultantIntegrationsTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SizedBox(
          height: ConsultantIntegrationsTokens.searchBarHeight,
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

class PremiumIntegrationsFilterStrip extends StatelessWidget {
  const PremiumIntegrationsFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final IntegrationCenterFilter selected;
  final ValueChanged<IntegrationCenterFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantIntegrationsTokens.horizontal,
        0,
        ConsultantIntegrationsTokens.horizontal,
        ConsultantIntegrationsTokens.sectionGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ClipRect(
          child: SizedBox(
            height: ConsultantIntegrationsTokens.filterStripHeight,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
                overscroll: false,
              ),
              child: ListView.separated(
                key: const Key('integration_filter_strip_scroll'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                cacheExtent: 360,
                padding: const EdgeInsets.only(right: 4),
                itemCount: IntegrationCenterFilter.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final filter = IntegrationCenterFilter.values[index];
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
