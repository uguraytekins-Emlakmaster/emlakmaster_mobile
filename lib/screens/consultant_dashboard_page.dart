import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/debug/ui_v2_debug.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/performance/deferred_mount_section.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_dashboard_reminder.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/features/deal_discovery/presentation/widgets/discovery_panel.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/consultant_dashboard_layout.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_action_anchor.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_hero_card.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_kpi_bento.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_operational_feed.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_quick_nav.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_support_cards.dart';
import 'package:emlakmaster_mobile/screens/providers/consultant_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Danışman paneli — günlük operasyon kokpiti: Hero → KPI → hızlı erişim → CTA → operasyon.
class ConsultantDashboardPage extends ConsumerWidget {
  const ConsultantDashboardPage({super.key});

  static String _greetingFromUser(User? user) {
    final hour = DateTime.now().hour;
    final salutation =
        hour < 12 ? 'Günaydın' : (hour < 18 ? 'İyi günler' : 'İyi akşamlar');
    final String firstName;
    final dn = user?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      firstName = dn.split(RegExp(r'\s+')).first;
    } else if (user?.email != null) {
      firstName = user!.email!.split('@').first;
    } else {
      firstName = 'Danışman';
    }
    return '$salutation, $firstName';
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    ref.invalidate(todayCallsCountProvider);
    if (uid.isNotEmpty) {
      ref.invalidate(advisorOpenTasksCountProvider(uid));
      ref.invalidate(advisorPipelineCountProvider(uid));
      ref.invalidate(agentWeeklyCallCountProvider(uid));
    }
    ref.invalidate(resurrectionQueueProvider);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final premium = PremiumThemeExtension.of(context);
      final lean = ref.watch(
        featureFlagsProvider.select(
          (a) => a.valueOrNull?[AppConstants.keyV1LeanProduct] ?? true,
        ),
      );
      final summaryBottomPad =
          DashboardLayoutTokens.shellScrollBottomPadding(context);
      final greeting = ref.watch(
        currentUserProvider.select((v) => _greetingFromUser(v.valueOrNull)),
      );

      if (kDebugMode) {
        logUiV2Active(
          'consultant_dashboard',
          detail:
              'layout=${ConsultantDashboardLayout.layoutVersion} widget=ConsultantDashboardPage fingerprint=${ConsultantDashboardLayout.fingerprint}',
        );
        AppLogger.state(
          '[ConsultantDashboard] mounted layout=${ConsultantDashboardLayout.layoutVersion} '
          'hero=ConsultantDashboardHeroCard kpi=ConsultantDashboardKpiBento quickNav=ConsultantDashboardQuickNavGrid',
        );
      }

      return PremiumShellBackdrop(
        debugScreenName: 'consultant_dashboard',
        debugDetail: ConsultantDashboardLayout.layoutVersion,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: RepaintBoundary(
              child: RefreshIndicator(
                onRefresh: () => _onRefresh(ref),
                color: premium.champagneGold,
                backgroundColor: premium.glassSurface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  cacheExtent: 380,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DashboardLayoutTokens.horizontalPadding,
                          DashboardLayoutTokens.pageTopInset,
                          DashboardLayoutTokens.horizontalPadding,
                          DashboardLayoutTokens.pageBottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ConsultantDashboardHeroCard(greeting: greeting),
                            const SizedBox(height: DesignTokens.space4),
                            PremiumSearchBar(
                              hintText: 'Müşteri, ilan veya görev ara…',
                              showMic: true,
                              onSubmitted: (_) {
                                ref
                                    .read(mainShellShortcutProvider.notifier)
                                    .enqueue(
                                        MainShellShortcut.openCustomersTab);
                                context.go(AppRouter.routeHome);
                              },
                              trailing: Material(
                                color: premium.champagneGold
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusMd),
                                child: InkWell(
                                  onTap: () {
                                    ref
                                        .read(
                                            mainShellShortcutProvider.notifier)
                                        .enqueue(MainShellShortcut
                                            .openCustomersTab);
                                    context.go(AppRouter.routeHome);
                                  },
                                  borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusMd),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Icon(Icons.auto_awesome_rounded,
                                        color: premium.champagneGold, size: 22),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: DesignTokens.space5),
                            DeferredMountSection.dashboardPrimary(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const PremiumSectionHeader(
                                    label: 'Günün özeti',
                                    icon: Icons.insights_rounded,
                                  ),
                                  ShellScreenReadyListener(
                                    screenName: 'consultant_dashboard',
                                    provider: todayCallsCountProvider,
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ConsultantDashboardKpiBento(),
                                        SizedBox(height: DesignTokens.space5),
                                        PremiumSectionHeader(
                                          label: 'Hızlı erişim',
                                          icon: Icons.grid_view_rounded,
                                        ),
                                        ConsultantDashboardQuickNavGrid(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const DeferredMountSection.dashboardOperational(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PostCallCaptureDashboardReminder(),
                                  SizedBox(
                                      height: DashboardLayoutTokens
                                          .gapOperationalTight),
                                  ConsultantDashboardActionAnchor(),
                                ],
                              ),
                            ),
                            const SizedBox(
                                height: DashboardLayoutTokens.gapOperational),
                            const ConsultantDashboardDeferredOperationalFeed(),
                          ],
                        ),
                      ),
                    ),
                    if (!lean) ...[
                      const SliverToBoxAdapter(
                        child: SizedBox(
                            height: DashboardLayoutTokens.gapInsightSection),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: DashboardLayoutTokens.horizontalPadding,
                          ),
                          child: ConsultantDashboardInsightFeed(),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                            height: DashboardLayoutTokens.gapInsightSection),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: DashboardLayoutTokens.horizontalPadding,
                          ),
                          child: DiscoveryPanel(),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                            height: DashboardLayoutTokens.gapInsightSection),
                      ),
                      const SliverToBoxAdapter(child: MasterTicker()),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                            height: DashboardLayoutTokens.gapInsightSection),
                      ),
                      const SliverToBoxAdapter(child: FinanceBar()),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                            height: DashboardLayoutTokens.gapInsightSection),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: DashboardLayoutTokens.horizontalPadding,
                          ),
                          child: MarketPulsePanel(),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                            height: DashboardLayoutTokens.gapInsightSection),
                      ),
                      const SliverToBoxAdapter(
                        child: DeferredMountSection.dashboardInsight(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  DashboardLayoutTokens.horizontalPadding,
                            ),
                            child: ConsultantDashboardAcademyCard(),
                          ),
                        ),
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: summaryBottomPad + DesignTokens.space3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.e('ConsultantDashboardPage build', e, st);
      final ext = AppThemeExtension.of(context);
      return Material(
        color: ext.background,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: ext.accent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Danisman paneli hazirlanamadi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontSize: DesignTokens.fontSizeLg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ekran yuklenirken bir sorun olustu. Uygulama kabugu aktif; ana sekmeler kullanilmaya devam edebilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: DesignTokens.fontSizeSm,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
