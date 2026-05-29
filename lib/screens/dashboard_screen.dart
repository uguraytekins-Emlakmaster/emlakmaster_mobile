import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/providers/admin_office_health_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_quick_routes.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_skeleton.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_urgent_section.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_alerts_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_intelligence_summary_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_smart_task_suggestions_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/execution_reminders_providers.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/manager_escalations_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_dashboard_reminder.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/execution_reminders_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/manager_escalations_card.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/manager_revenue_summary_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/broker_dashboard_alerts_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/smart_task_suggestions_card.dart';
import 'package:emlakmaster_mobile/core/performance/deferred_mount_section.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/dashboard_kpi_section.dart';
import 'package:emlakmaster_mobile/screens/providers/consultant_dashboard_kpi_providers.dart';
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
import 'package:emlakmaster_mobile/widgets/dashboard_notifications_sheet.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:emlakmaster_mobile/widgets/revenue_leak_tracker.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:emlakmaster_mobile/features/deal_discovery/presentation/widgets/discovery_panel.dart';
import 'package:emlakmaster_mobile/features/daily_brief/presentation/widgets/daily_brief_panel.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/features/hot_lead_radar/presentation/widgets/hot_lead_radar_panel.dart';
import 'package:emlakmaster_mobile/features/missed_opportunities/presentation/widgets/missed_opportunities_panel.dart';
import 'package:emlakmaster_mobile/features/opportunity_radar/presentation/widgets/opportunity_radar_widget.dart';
import 'package:emlakmaster_mobile/features/region_demand_map/presentation/widgets/region_demand_map_panel.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yönetici / broker **Komuta Merkezi** — executive command layer.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    final lean = ref
            .read(featureFlagsProvider)
            .valueOrNull?[AppConstants.keyV1LeanProduct] ??
        true;
    ref.invalidate(externalListingsStreamProvider);
    ref.invalidate(adminCommandSnapshotProvider);
    ref.invalidate(brokerDashboardIntelligenceSummaryProvider);
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

  List<Widget> _executiveChromeSlivers(
    WidgetRef ref,
    BuildContext context,
  ) {
    final uid =
        ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    final intelAsync = ref.watch(brokerDashboardIntelligenceSummaryProvider);
    final snapshotAsync = ref.watch(adminCommandSnapshotProvider);

    final headerActions = [
      SessionAvatarButton(size: AdminCommandTokens.headerAvatarSize),
      IconButton(
        tooltip: 'Bildirimler',
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: AdminCommandTokens.headerActionTap,
          minHeight: AdminCommandTokens.headerActionTap,
        ),
        icon: Icon(
          Icons.notifications_outlined,
          color: AppThemeExtension.of(context).textSecondary,
          size: AdminCommandTokens.headerActionIconSize,
        ),
        onPressed: uid.isEmpty
            ? null
            : () => showDashboardNotificationsSheet(context, uid: uid),
      ),
    ];

    return [
      SliverToBoxAdapter(
        child: PremiumAdminCommandHeader(
          title: ProductLabels.managerHome,
          subtitle: 'Ofis sağlığı · ekip aktivitesi · operasyon kontrolü',
          actions: headerActions,
        ),
      ),
      const SliverToBoxAdapter(child: RevenueLeakTracker()),
      snapshotAsync.when(
        loading: () => const AdminCommandSkeleton(),
        error: (_, __) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: EmptyState(
              compact: true,
              grouped: true,
              icon: Icons.cloud_off_outlined,
              title: 'Komuta özeti yüklenemedi',
              subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
              actionLabel: 'Tekrar dene',
              onAction: () {
                ref.invalidate(adminCommandSnapshotProvider);
              },
            ),
          ),
        ),
        data: (snapshot) => SliverList(
          delegate: SliverChildListDelegate([
            PremiumAdminHealthStrip(summary: snapshot.health),
            intelAsync.maybeWhen(
              data: (lines) => PremiumAdminIntelLines(
                recentLine: lines.recentLine,
                criticalLine: lines.criticalLine,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            PremiumAdminUrgentSection(items: snapshot.urgentItems),
            const PremiumAdminQuickRoutes(),
          ]),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final premium = PremiumThemeExtension.of(context);
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
      final analyticsEnabled = ref.watch(
        featureFlagsProvider.select(
          (a) => a.valueOrNull?[AppConstants.keyFeatureAnalytics] ?? true,
        ),
      );
      final scrollBottomPad =
          DashboardLayoutTokens.shellScrollBottomPadding(context);

      final gapOp = compact
          ? DashboardLayoutTokens.gapOperationalTight
          : DashboardLayoutTokens.gapOperational;
      final gapInsight = DashboardLayoutTokens.gapInsightSection.toDouble();
      const h = DashboardLayoutTokens.horizontalPadding;
      final bentoInsightContentW = MediaQuery.sizeOf(context).width - 2 * h;
      final stackBentoRadarRow = bentoInsightContentW < 520;
      final bentoSiblingGap =
          compact ? DesignTokens.space4 : DesignTokens.space6;

      Widget px(Widget child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: h),
            child: child,
          );

      final content = PremiumShellBackdrop(
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: SovereignArcWatermark(
              child: RepaintBoundary(
                child: RefreshIndicator(
                  onRefresh: () => _onRefresh(ref),
                  color: premium.champagneGold,
                  backgroundColor: premium.glassSurface,
                  child: CustomScrollView(
                    cacheExtent: 360,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      ..._executiveChromeSlivers(ref, context),
                      SliverToBoxAdapter(
                        child: DeferredMountSection.dashboardPrimary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const PremiumAdminSectionLabel(
                                label: 'Operasyonel müdahale',
                                secondary: 'Gerçek kuyruklar ve ekip sinyalleri',
                              ),
                              px(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const AiUsageIndicator(compact: true),
                                    SizedBox(height: gapOp * 0.85),
                                    const ManagerRevenueSummaryCard(),
                                    SizedBox(height: gapOp * 0.85),
                                    const ManagerEscalationsCard(),
                                    SizedBox(height: gapOp * 0.85),
                                    const PostCallCaptureDashboardReminder(),
                                    SizedBox(height: gapOp * 0.85),
                                    const BrokerDashboardAlertsCard(),
                                    SizedBox(height: gapOp * 0.85),
                                    const SmartTaskSuggestionsCard(),
                                    SizedBox(height: gapOp * 0.85),
                                    const ExecutionRemindersCard(
                                      surface: ExecutionReminderSurface.broker,
                                    ),
                                  ],
                                ),
                              ),
                              if (kpiBar) ...[
                                const PremiumAdminSectionLabel(label: 'Ofis momentumu'),
                                px(const DashboardKpiSection()),
                                SizedBox(height: gapOp * 0.75),
                              ],
                              const PremiumAdminSectionLabel(label: 'Çağrı sinyalleri'),
                              px(const PriorityCallSignalsCard()),
                              SizedBox(height: gapOp * 0.75),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: DeferredMountSection.dashboardSecondary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (analyticsEnabled) ...[
                                const PremiumAdminSectionLabel(
                                  label: 'İçgörü ve analitik',
                                ),
                                px(
                                  RainbowAnalyticsCenterCard(
                                    paddedContentWidth: bentoInsightContentW,
                                  ),
                                ),
                                SizedBox(height: gapOp * 0.75),
                              ],
                              const PremiumAdminSectionLabel(
                                label: 'Bağlantı ve sistem',
                              ),
                              px(const ManagerPlatformConnectionsSummaryCard()),
                              if (lean) ...[
                                SizedBox(height: gapOp * 0.75),
                                const PremiumAdminSectionLabel(
                                  label: 'Operasyonel odak',
                                  secondary: 'Lean görünüm',
                                ),
                                px(const LeanAdminTodayFocusCard()),
                                px(const LeanAdminOfficePulseCard()),
                              ],
                              if (!lean) ...[
                                SizedBox(height: gapOp),
                                px(const HotLeadRadarPanel()),
                                SizedBox(height: gapOp),
                                px(const MissedOpportunitiesPanel()),
                                SizedBox(height: gapOp),
                                if (dailyBrief) px(const DailyBriefPanel()),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (!lean)
                        SliverToBoxAdapter(
                          child: DeferredMountSection.dashboardInsight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: gapInsight),
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
                                        child: BentoPowerAnalytics(),
                                      ),
                                      SizedBox(
                                        height: compact
                                            ? DesignTokens.space4
                                            : DesignTokens.space6,
                                      ),
                                      if (stackBentoRadarRow)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            BentoSahaRadar(
                                              outerContentWidth:
                                                  bentoInsightContentW,
                                            ),
                                            SizedBox(
                                              height: compact
                                                  ? DesignTokens.space3
                                                  : DesignTokens.space4,
                                            ),
                                            const BentoAiNews(),
                                          ],
                                        )
                                      else
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: BentoSahaRadar(
                                                outerContentWidth:
                                                    bentoInsightContentW,
                                                splitWithSibling: true,
                                                siblingRowGap: bentoSiblingGap,
                                              ),
                                            ),
                                            SizedBox(width: bentoSiblingGap),
                                            const Expanded(child: BentoAiNews()),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: scrollBottomPad),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      return WelcomePatronOverlay(
        child: ShellScreenReadyListener(
          screenName: 'admin_dashboard',
          provider: todayCallsCountProvider,
          child: content,
        ),
      );
    } catch (e, st) {
      debugPrint('DashboardPage build error: $e');
      debugPrint(st.toString());
      final ext = AppThemeExtension.of(context);
      return Material(
        color: ext.background,
        child: Center(
          child: Text(
            'Bir hata oluştu, lütfen tekrar deneyin.',
            style: TextStyle(color: ext.textPrimary),
          ),
        ),
      );
    }
  }
}
