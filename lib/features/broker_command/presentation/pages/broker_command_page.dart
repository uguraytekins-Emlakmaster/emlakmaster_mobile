import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/unauthorized_screen.dart';

/// Broker Command — [DashboardPage] ile aynı **3 katman** ve [DashboardLayoutTokens] ritmi.
class BrokerCommandPage extends ConsumerWidget {
  const BrokerCommandPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(displayRoleProvider);
    return roleAsync.when(
      loading: () {
        final ext = AppThemeExtension.of(context);
        return Scaffold(
          backgroundColor: ext.background,
          body: Center(child: CircularProgressIndicator(color: ext.accent)),
        );
      },
      error: (_, __) => const UnauthorizedScreen(message: 'Rol yüklenemedi.'),
      data: (role) {
        if (!FeaturePermission.canViewWarRoom(role)) {
          return const UnauthorizedScreen(
            message: 'Broker Command ekranına sadece yönetici ve operasyon erişebilir.',
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
    const h = DashboardLayoutTokens.horizontalPadding;
    const gapOp = DashboardLayoutTokens.gapOperational;
    final gapInsight = DashboardLayoutTokens.gapInsightSection.toDouble();
    final bottomPad = DashboardLayoutTokens.shellScrollBottomPadding(context);

    Widget px(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: h),
          child: child,
        );

    return Scaffold(
      backgroundColor: ext.background,
      appBar: emlakAppBar(
        context,
        title: Text(
          'Broker Command',
          style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w700),
        ),
        backgroundColor: ext.background,
        foregroundColor: ext.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        color: ext.accent,
        backgroundColor: ext.surface,
        child: ListView(
          padding: EdgeInsets.only(
            top: DashboardLayoutTokens.pageTopInset,
            bottom: bottomPad,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // —— Hero ——
            px(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rainbow Gayrimenkul',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Operasyonel komuta ve piyasa görünümü',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ext.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: DashboardLayoutTokens.gapHeroToOperational.toDouble()),
            // —— Operational ——
            px(const RainbowAnalyticsCenterCard()),
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
                  borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
                  border: Border.all(color: ext.borderSubtle),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ekip performansı',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: ext.accent,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Çağrı yoğunluğu ve satış metrikleri burada listelenecek.',
                        style: TextStyle(color: ext.textSecondary, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
