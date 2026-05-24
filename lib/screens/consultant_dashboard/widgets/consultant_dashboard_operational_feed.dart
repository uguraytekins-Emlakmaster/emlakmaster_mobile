import 'package:emlakmaster_mobile/core/performance/deferred_mount_section.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/sync_delayed_customers_dashboard_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/execution_reminders_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/priority_call_signals_card.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/ai_usage_indicator.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/consultant_performance_strip.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_intelligence_dashboard_section.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_support_cards.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

/// Secondary operational feed — deferred to keep above-the-fold cockpit fast.
class ConsultantDashboardOperationalFeed extends StatelessWidget {
  const ConsultantDashboardOperationalFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSectionHeader(
          label: 'Operasyon',
          icon: Icons.bolt_rounded,
        ),
        AiUsageIndicator(),
        SizedBox(height: DashboardLayoutTokens.gapOperationalTight),
        ConsultantPerformanceStrip(),
        SizedBox(height: DashboardLayoutTokens.gapOperational),
        PremiumSectionHeader(
          label: 'Fırsat ve gelir motoru',
          icon: Icons.trending_up_rounded,
        ),
        SizedBox(height: DesignTokens.space2),
        RevenueIntelligenceDashboardSection(),
        SizedBox(height: DashboardLayoutTokens.gapOperationalTight),
        ExecutionRemindersCard(
          surface: ExecutionReminderSurface.consultant,
        ),
        SizedBox(height: DashboardLayoutTokens.gapOperational),
        PriorityCallSignalsCard(),
        SizedBox(height: DashboardLayoutTokens.gapOperational),
        SyncDelayedCustomersDashboardCard(),
        SizedBox(height: DashboardLayoutTokens.gapOperational),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConsultantDashboardPipelineChampionCard(),
      ],
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
