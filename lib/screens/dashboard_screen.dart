import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/dashboard_kpi_section.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/sovereign_arc_watermark.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/welcome_patron_overlay.dart';
import 'package:emlakmaster_mobile/features/external_listings/presentation/providers/external_listings_provider.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/widgets/bento_ai_news.dart';
import 'package:emlakmaster_mobile/widgets/bento_analytics.dart';
import 'package:emlakmaster_mobile/widgets/bento_saha_radar.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/widgets/rainbow_analytics_center_card.dart';
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

/// Yönetici / broker **Dashboard** — danışman paneliyle aynı sistem:
/// **Hero** (ofis kimliği) → **Operational** (KPI, komuta, sıcak/kaçırılan, günlük özet) → **Insight** (pipeline, ekonomi, ticker, harita, analitik).
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
      final ext = AppThemeExtension.of(context);
      final flags = ref.watch(featureFlagsProvider).valueOrNull;
      final compact = flags?[AppConstants.keyCompactDashboard] ?? false;
      final scrollBottomPad = DashboardLayoutTokens.shellScrollBottomPadding(context);
      final kpiBar = flags?[AppConstants.keyFeatureKpiBar] ?? true;
      final marketPulse = flags?[AppConstants.keyFeatureMarketPulse] ?? true;
      final dailyBrief = flags?[AppConstants.keyFeatureDailyBrief] ?? true;

      final gapOp = compact
          ? DashboardLayoutTokens.gapOperationalTight
          : DashboardLayoutTokens.gapOperational;
      final gapHero =
          compact ? 4.0 : DashboardLayoutTokens.gapHeroToOperational.toDouble();
      final gapInsight = DashboardLayoutTokens.gapInsightSection.toDouble();
      const h = DashboardLayoutTokens.horizontalPadding;

      Widget px(Widget child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: h),
            child: child,
          );

      final content = Scaffold(
        backgroundColor: ext.background,
        body: SafeArea(
          child: SovereignArcWatermark(
            child: RepaintBoundary(
              child: ColoredBox(
                color: ext.background,
                child: RefreshIndicator(
                  onRefresh: () => _onRefresh(ref),
                  color: ext.accent,
                  backgroundColor: ext.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: scrollBottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // —— Layer 1: Hero — ofis kimliği, uyarı şeridi ——
                        const DashboardTopAppBar(),
                        SizedBox(height: gapHero),
                        // —— Layer 2: Operational — KPI, komuta, acil, özet ——
                        if (kpiBar) px(const DashboardKpiSection()),
                        if (kpiBar) SizedBox(height: gapOp),
                        px(const RainbowAnalyticsCenterCard()),
                        SizedBox(height: gapOp),
                        px(const HotLeadRadarPanel()),
                        SizedBox(height: gapOp),
                        px(const MissedOpportunitiesPanel()),
                        SizedBox(height: gapOp),
                        if (dailyBrief) px(const DailyBriefPanel()),
                        SizedBox(height: gapInsight),
                        // —— Layer 3: Insight — pipeline, ekonomi, ticker, harita, analitik ——
                        px(const DiscoveryPanel()),
                        SizedBox(height: gapInsight),
                        const FinanceBar(),
                        SizedBox(height: gapInsight),
                        if (marketPulse) px(const MarketPulsePanel()),
                        if (marketPulse) SizedBox(height: gapInsight),
                        px(const MasterTicker()),
                        SizedBox(height: gapInsight),
                        px(const OpportunityRadarWidget()),
                        SizedBox(height: gapInsight),
                        px(const RegionDemandMapPanel()),
                        SizedBox(height: gapInsight),
                        px(
                          Column(
                            children: [
                              const RepaintBoundary(child: BentoPowerAnalytics()),
                              SizedBox(height: compact ? 16 : 24),
                              LayoutBuilder(
                                builder: (context, c) {
                                  final stack = c.maxWidth < 520;
                                  if (stack) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const BentoSahaRadar(),
                                        SizedBox(height: compact ? 12 : 16),
                                        const BentoAiNews(),
                                      ],
                                    );
                                  }
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Expanded(child: BentoSahaRadar()),
                                      SizedBox(width: compact ? 16 : 24),
                                      const Expanded(child: BentoAiNews()),
                                    ],
                                  );
                                },
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
      final ext = AppThemeExtension.of(context);
      return Scaffold(
        backgroundColor: ext.background,
        body: Center(
          child: Text(
            'Bir hata oluştu, lütfen tekrar deneyin.',
            style: TextStyle(color: ext.textPrimary),
          ),
        ),
      );
    }
  }
}
