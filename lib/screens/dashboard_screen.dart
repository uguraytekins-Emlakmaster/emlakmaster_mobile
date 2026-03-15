import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/dashboard_kpi_section.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/welcome_patron_overlay.dart';
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
import 'package:emlakmaster_mobile/widgets/top_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final size = MediaQuery.of(context).size;
      final content = Scaffold(
        body: SafeArea(
          child: Container(
            width: size.width,
            height: size.height,
            color: const Color(0xFF0D1117),
            child: const SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardTopAppBar(),
                  SizedBox(height: 16),
                  DashboardKpiSection(),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: MasterTicker(),
                  ),
                  SizedBox(height: 24),
                  FinanceBar(),
                  SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: DiscoveryPanel(),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: MarketPulsePanel(),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: OpportunityRadarWidget(),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: HotLeadRadarPanel(),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: DailyBriefPanel(),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: MissedOpportunitiesPanel(),
                  ),
                  SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
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
      );
      return WelcomePatronOverlay(child: content);
    } catch (e, st) {
      debugPrint('DashboardPage build error: $e');
      debugPrint(st.toString());
      return const Scaffold(
        body: Center(
          child: Text(
            'Bir hata oluştu, lütfen tekrar deneyin.',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Color(0xFF0D1117),
      );
    }
  }
}
