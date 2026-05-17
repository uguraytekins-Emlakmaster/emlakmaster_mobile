import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/kpi_bar.dart';
import 'package:emlakmaster_mobile/screens/providers/consultant_dashboard_kpi_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard KPI bar'ı — tek katman Riverpod (iç içe StreamBuilder yok).
class DashboardKpiSection extends ConsumerWidget {
  const DashboardKpiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayCalls = ref.watch(todayCallsCountProvider);
    final agentsKpi = ref.watch(brokerAgentsKpiSnapshotProvider);
    final openTasks = ref.watch(brokerOpenTasksCountProvider);

    if (todayCalls.isLoading && !todayCalls.hasValue) {
      return SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppThemeExtension.of(context).accent,
            ),
          ),
        ),
      );
    }

    final totalCalls = todayCalls.valueOrNull ?? 0;
    final agentSnap = agentsKpi.valueOrNull ?? BrokerAgentsKpiSnapshot.empty;
    final missedCalls = agentSnap.missedCalls;
    final answeredCalls =
        totalCalls > missedCalls ? totalCalls - missedCalls : totalCalls;
    final followUpPending = openTasks.valueOrNull ?? 0;

    return KpiBar(
      totalCalls: totalCalls,
      answeredCalls: answeredCalls,
      missedCalls: missedCalls,
      followUpPending: followUpPending,
      activeAdvisors: agentSnap.activeAdvisors,
      activeCalls: agentSnap.activeCalls,
    );
  }
}
