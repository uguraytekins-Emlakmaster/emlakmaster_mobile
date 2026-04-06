import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/execution_reminders_providers.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_alerts_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_smart_task_suggestions_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/manager_escalations_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_dashboard_reminder.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/execution_reminders_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/manager_escalations_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/broker_dashboard_intelligence_summary_card.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/manager_revenue_summary_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/broker_dashboard_alerts_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/smart_task_suggestions_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/dashboard_kpi_section.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/lean_admin_dashboard_balance_cards.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/manager_platform_connections_summary_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/priority_call_signals_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/sovereign_arc_watermark.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/welcome_patron_overlay.dart';
import 'package:emlakmaster_mobile/features/external_listings/presentation/providers/external_listings_provider.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/widgets/bento_ai_news.dart';
import 'package:emlakmaster_mobile/widgets/bento_analytics.dart';
import 'package:emlakmaster_mobile/widgets/bento_saha_radar.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/widgets/rainbow_analytics_center_card.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/ai_usage_indicator.dart';
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
    final lean = ref
            .read(featureFlagsProvider)
            .valueOrNull?[AppConstants.keyV1LeanProduct] ??
        true;
    ref.invalidate(externalListingsStreamProvider);
    if (!lean) {
      ref.invalidate(marketHeatmapProvider);
      ref.invalidate(discoveryItemsProvider);
      ref.invalidate(dailyBriefProvider);
      ref.invalidate(missedOpportunitiesProvider);
    }
    ref.invalidate(intelligenceRunTriggerProvider);
    ref.invalidate(managerEscalationsProvider);
    ref.invalidate(brokerExecutionRemindersProvider);
    if (lean) {
      ref.invalidate(brokerSmartTaskSuggestionsProvider);
      ref.invalidate(brokerDashboardAlertsProvider);
    }
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final ext = AppThemeExtension.of(context);
      // Granular select: tam Map değişince değil, ilgili bayraklar değişince yeniden çiz.
      final compact = ref.watch(
        featureFlagsProvider.select(
          (a) => a.valueOrNull?[AppConstants.keyCompactDashboard] ?? false,
        ),
      );
      final lean = ref.watch(
        featureFlagsProvider.select(
          (a) => a.valueOrNull?[AppConstants.keyV1LeanProduct] ?? true,
        ),
      );
      final kpiBar = ref.watch(
        featureFlagsProvider.select(
          (a) => a.valueOrNull?[AppConstants.keyFeatureKpiBar] ?? true,
        ),
      );
      final marketPulse = ref.watch(
        featureFlagsProvider.select((a) {
          final m = a.valueOrNull;
          return (m?[AppConstants.keyFeatureMarketPulse] ?? true) &&
              !(m?[AppConstants.keyV1LeanProduct] ?? true);
        }),
      );
      final dailyBrief = ref.watch(
        featureFlagsProvider.select((a) {
          final m = a.valueOrNull;
          return (m?[AppConstants.keyFeatureDailyBrief] ?? true) &&
              !(m?[AppConstants.keyV1LeanProduct] ?? true);
        }),
      );
      final scrollBottomPad =
          DashboardLayoutTokens.shellScrollBottomPadding(context);

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
                        px(
                          const RepaintBoundary(
                            child: BrokerDashboardIntelligenceSummaryCard(),
                          ),
                        ),
                        px(const AiUsageIndicator(compact: true)),
                        px(const ManagerRevenueSummaryCard()),
                        px(const ManagerEscalationsCard()),
                        px(const PostCallCaptureDashboardReminder()),
                        px(const BrokerDashboardAlertsCard()),
                        px(const SmartTaskSuggestionsCard()),
                        px(const ExecutionRemindersCard(
                            surface: ExecutionReminderSurface.broker)),
                        // —— Layer 2: Operational — KPI, komuta, acil, özet ——
                        if (kpiBar) px(const DashboardKpiSection()),
                        if (kpiBar) SizedBox(height: gapOp),
                        px(const PriorityCallSignalsCard()),
                        if (kpiBar) SizedBox(height: gapOp),
                        px(const RainbowAnalyticsCenterCard()),
                        SizedBox(height: gapOp),
                        px(const ManagerPlatformConnectionsSummaryCard()),
                        if (lean) ...[
                          px(const LeanAdminTodayFocusCard()),
                          px(const LeanAdminOfficePulseCard()),
                        ],
                        if (!lean) ...[
                          px(const HotLeadRadarPanel()),
                          SizedBox(height: gapOp),
                          px(const MissedOpportunitiesPanel()),
                          SizedBox(height: gapOp),
                        ],
                        if (dailyBrief) px(const DailyBriefPanel()),
                        if (!lean) ...[
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
                                const RepaintBoundary(
                                    child: BentoPowerAnalytics()),
                                SizedBox(height: compact ? 16 : 24),
                                LayoutBuilder(
                                  builder: (context, c) {
                                    final stack = c.maxWidth < 520;
                                    if (stack) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const BentoSahaRadar(),
                                          SizedBox(height: compact ? 12 : 16),
                                          const BentoAiNews(),
                                        ],
                                      );
                                    }
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
