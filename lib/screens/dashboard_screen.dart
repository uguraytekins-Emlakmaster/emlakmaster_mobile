import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/dashboard_kpi_section.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/sovereign_arc_watermark.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/welcome_patron_overlay.dart';
import 'package:emlakmaster_mobile/features/external_listings/presentation/providers/external_listings_provider.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/widgets/bento_ai_news.dart';
import 'package:emlakmaster_mobile/widgets/bento_analytics.dart';
import 'package:emlakmaster_mobile/widgets/bento_saha_radar.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:emlakmaster_mobile/features/deal_discovery/presentation/widgets/discovery_panel.dart';
import 'package:emlakmaster_mobile/features/daily_brief/presentation/widgets/daily_brief_panel.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/features/hot_lead_radar/presentation/widgets/hot_lead_radar_panel.dart';
import 'package:emlakmaster_mobile/features/missed_opportunities/presentation/widgets/missed_opportunities_panel.dart';
import 'package:emlakmaster_mobile/features/opportunity_radar/presentation/widgets/opportunity_radar_widget.dart';
import 'package:emlakmaster_mobile/features/region_demand_map/presentation/widgets/region_demand_map_panel.dart';
import 'package:emlakmaster_mobile/widgets/top_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(externalListingsStreamProvider);
    ref.invalidate(marketHeatmapProvider);
    ref.invalidate(discoveryItemsProvider);
    ref.invalidate(dailyBriefProvider);
    ref.invalidate(missedOpportunitiesProvider);
    ref.invalidate(intelligenceRunTriggerProvider);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
      final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
      final size = MediaQuery.of(context).size;
      final flags = ref.watch(featureFlagsProvider).valueOrNull;
      final kpiBar = flags?[AppConstants.keyFeatureKpiBar] ?? true;
      final marketPulse = flags?[AppConstants.keyFeatureMarketPulse] ?? true;
      final dailyBrief = flags?[AppConstants.keyFeatureDailyBrief] ?? true;
      final content = Scaffold(
        body: SafeArea(
          child: SovereignArcWatermark(
            child: RepaintBoundary(
              child: Container(
                width: size.width,
                height: size.height,
                color: bg,
                child: RefreshIndicator(
              onRefresh: () => _onRefresh(ref),
              color: DesignTokens.antiqueGold,
              backgroundColor: surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: DesignTokens.contentPaddingHorizontal,
                  right: DesignTokens.contentPaddingHorizontal,
                  bottom: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DashboardTopAppBar(),
                    const SizedBox(height: 16),
                    if (kpiBar) const DashboardKpiSection(),
                    if (kpiBar) const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.contentPaddingHorizontal),
                      child: MasterTicker(),
                    ),
                    const SizedBox(height: DesignTokens.space6),
                    const FinanceBar(),
                    const SizedBox(height: DesignTokens.space6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.contentPaddingHorizontal),
                      child: DiscoveryPanel(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    if (marketPulse)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: DesignTokens.contentPaddingHorizontal),
                        child: MarketPulsePanel(),
                      ),
                    if (marketPulse) const SizedBox(height: DesignTokens.space4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.contentPaddingHorizontal),
                      child: OpportunityRadarWidget(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.contentPaddingHorizontal),
                      child: HotLeadRadarPanel(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    if (dailyBrief)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: DesignTokens.contentPaddingHorizontal),
                        child: DailyBriefPanel(),
                      ),
                    if (dailyBrief) const SizedBox(height: DesignTokens.space4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.contentPaddingHorizontal),
                      child: RegionDemandMapPanel(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.contentPaddingHorizontal),
                      child: MissedOpportunitiesPanel(),
                    ),
                    const SizedBox(height: DesignTokens.space6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.contentPaddingHorizontal),
                      child: Column(
                        children: [
                          BentoPowerAnalytics(),
                          SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: BentoSahaRadar()),
                              SizedBox(width: 24),
                              Expanded(child: BentoAiNews()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
        ),
      );
      return WelcomePatronOverlay(child: content);
    } catch (e, st) {
      debugPrint('DashboardPage build error: $e');
      debugPrint(st.toString());
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
      final fg = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text(
            'Bir hata oluştu, lütfen tekrar deneyin.',
            style: TextStyle(color: fg),
          ),
        ),
      );
    }
  }
}
