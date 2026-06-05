import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/widgets/rainbow_analytics_center_card.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/daily_brief/presentation/widgets/daily_brief_panel.dart';
import 'package:emlakmaster_mobile/features/deal_discovery/presentation/widgets/discovery_panel.dart';
import 'package:emlakmaster_mobile/features/hot_lead_radar/presentation/widgets/hot_lead_radar_panel.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/features/missed_opportunities/presentation/widgets/missed_opportunities_panel.dart';
import 'package:emlakmaster_mobile/features/opportunity_radar/presentation/widgets/opportunity_radar_widget.dart';
import 'package:emlakmaster_mobile/features/region_demand_map/presentation/widgets/region_demand_map_panel.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/unauthorized_screen.dart';

/// Broker Command — [DashboardPage] ile aynı **3 katman** ve [DashboardLayoutTokens] ritmi.
class BrokerCommandPage extends ConsumerWidget {
  const BrokerCommandPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gerçek rol (override DEĞİL) ile yetki kontrolü.
    final roleAsync = ref.watch(currentRoleProvider);
    return roleAsync.when(
      loading: () {
        final premium = PremiumThemeExtension.of(context);
        return PremiumShellBackdrop(
          child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
              child: CircularProgressIndicator(color: premium.champagneGold)),
        ),
        );
      },
      error: (_, __) => const UnauthorizedScreen(
        message: 'Yetki bilgisi alınamadı.',
      ),
      data: (role) {
        if (!FeaturePermission.canViewWarRoom(role)) {
          return const UnauthorizedScreen(
            message: 'Bu alan yalnızca yönetim ve operasyon için açıktır.',
          );
        }
        return const _BrokerCommandBody();
      },
    );
  }
}

class _BrokerCommandBody extends StatelessWidget {
  const _BrokerCommandBody();

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    const h = DashboardLayoutTokens.horizontalPadding;
    final paddedContentW = MediaQuery.sizeOf(context).width - 2 * h;
    const gapOp = DashboardLayoutTokens.gapOperational;
    final gapInsight = DashboardLayoutTokens.gapInsightSection.toDouble();
    final bottomPad = DashboardLayoutTokens.shellScrollBottomPadding(context);

    Widget px(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: h),
          child: child,
        );

    return PremiumShellBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: emlakAppBar(
        context,
        title: Text(
          ProductLabels.operationsDeck,
          style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: ext.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        color: premium.champagneGold,
        backgroundColor: premium.glassSurface,
        child: ListView(
          padding: EdgeInsets.only(
            top: DashboardLayoutTokens.pageTopInset,
            bottom: bottomPad,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // —— Hero ——
            px(
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ext.surfaceElevated,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusCardPrimary),
                  border: Border.all(color: ext.border.withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: ext.shadowColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KOMUTA',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: premium.champagneGold.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Text(
                        'Rainbow Gayrimenkul',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: ext.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        'Operasyon, piyasa ve ekip ritmi tek bakışta önünüzde.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ext.textSecondary,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
                height: DashboardLayoutTokens.gapHeroToOperational.toDouble()),
            // —— Operational ——
            px(RainbowAnalyticsCenterCard(
              paddedContentWidth: paddedContentW,
            )),
            const SizedBox(height: gapOp),
            px(const MarketPulsePanel()),
            const SizedBox(height: gapOp),
            px(const HotLeadRadarPanel()),
            const SizedBox(height: gapOp),
            px(const MissedOpportunitiesPanel()),
            const SizedBox(height: gapOp),
            px(const DailyBriefPanel()),
            SizedBox(height: gapInsight),
            // —— Insight ——
            px(const DiscoveryPanel()),
            SizedBox(height: gapInsight),
            const FinanceBar(),
            SizedBox(height: gapInsight),
            px(const MasterTicker()),
            SizedBox(height: gapInsight),
            px(const OpportunityRadarWidget()),
            SizedBox(height: gapInsight),
            px(const RegionDemandMapPanel()),
            SizedBox(height: gapInsight),
            px(
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ext.surfaceElevated,
                  borderRadius:
                      BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
                  border: Border.all(color: ext.borderSubtle),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kadro ritmi',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: premium.champagneGold,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Çağrı yoğunluğu ve satış akışı burada toplanacak.',
                        style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
