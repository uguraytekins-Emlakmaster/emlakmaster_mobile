import 'package:emlakmaster_mobile/core/performance/deferred_mount_section.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/sync_delayed_customers_dashboard_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/execution_reminders_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/priority_call_signals_card.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/ai_usage_indicator.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/consultant_performance_strip.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_intelligence_dashboard_section.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/consultant_dashboard_tokens.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_section_header.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_support_cards.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:flutter/material.dart';

/// Secondary operational feed — premium ops shells matching cockpit language.
class ConsultantDashboardOperationalFeed extends StatelessWidget {
  const ConsultantDashboardOperationalFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConsultantDashboardSectionHeader(
          label: 'Operasyon',
          subtitle: 'AI kullanımı ve günlük momentum',
          icon: Icons.bolt_rounded,
        ),
        ConsultantDashboardOpsShell(
          child: AiUsageIndicator(),
        ),
        SizedBox(height: ConsultantDashboardTokens.blockGap),
        ConsultantDashboardOpsShell(
          tier: ConsultantDashboardOpsTier.performance,
          child: ConsultantPerformanceStrip(),
        ),
        SizedBox(height: ConsultantDashboardTokens.sectionGap),
        ConsultantDashboardSectionHeader(
          label: 'Fırsat ve gelir motoru',
          subtitle: 'Gelir sinyalleri ve takip hatırlatmaları',
          icon: Icons.trending_up_rounded,
        ),
        ConsultantDashboardOpsShell(
          tier: ConsultantDashboardOpsTier.revenue,
          child: RevenueIntelligenceDashboardSection(),
        ),
        SizedBox(height: ConsultantDashboardTokens.blockGap),
        ConsultantDashboardOpsShell(
          child: ExecutionRemindersCard(
            surface: ExecutionReminderSurface.consultant,
          ),
        ),
        SizedBox(height: ConsultantDashboardTokens.blockGap),
        ConsultantDashboardOpsShell(
          child: PriorityCallSignalsCard(),
        ),
        SizedBox(height: ConsultantDashboardTokens.blockGap),
        ConsultantDashboardOpsShell(
          child: SyncDelayedCustomersDashboardCard(),
        ),
        SizedBox(height: ConsultantDashboardTokens.blockGap),
        ConsultantDashboardGoalStatsRow(),
      ],
    );
  }
}

/// Insight cards for full product mode (lean=false).
class ConsultantDashboardInsightFeed extends StatelessWidget {
  const ConsultantDashboardInsightFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConsultantDashboardOpsShell(
      tier: ConsultantDashboardOpsTier.performance,
      child: ConsultantDashboardPipelineChampionCard(),
    );
  }
}

/// Nested defer for heaviest operational cards after first paint.
class ConsultantDashboardDeferredOperationalFeed extends StatelessWidget {
  const ConsultantDashboardDeferredOperationalFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeferredMountSection.dashboardSecondary(
      child: ConsultantDashboardOperationalFeed(),
    );
  }
}
