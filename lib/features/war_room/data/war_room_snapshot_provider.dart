import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/providers/admin_office_health_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_alerts_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/manager_escalations_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/utils/war_room_intervention_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tek snapshot — admin komuta katmanı ile aynı kaynakları paylaşır; ek sorgu yok.
final warRoomInterventionSnapshotProvider =
    Provider.autoDispose<AsyncValue<WarRoomInterventionSnapshot>>((ref) {
  final commandAsync = ref.watch(adminCommandSnapshotProvider);

  return commandAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (command) {
      final alerts = ref.watch(brokerDashboardAlertsProvider).valueOrNull ?? [];
      final escalations =
          ref.watch(managerEscalationsProvider).valueOrNull ?? [];
      final followUp = ref.watch(resurrectionQueueProvider).valueOrNull ?? [];
      final revenue = ref.watch(brokerRevenueDashboardSnapshotProvider);
      final openTasks = ref.watch(brokerOpenTasksCountProvider).valueOrNull ?? 0;

      final lanes = buildWarRoomPriorityLanes(health: command.health);
      final interventions = buildWarRoomInterventionRows(
        escalations: escalations,
        alerts: alerts,
        followUp: followUp,
        syncRisk: revenue.atRiskSync,
        openTasks: openTasks,
      );

      return AsyncValue.data(
        WarRoomInterventionSnapshot(
          health: command.health,
          lanes: lanes,
          interventions: interventions,
        ),
      );
    },
  );
});

void invalidateWarRoomData(WidgetRef ref) {
  ref.invalidate(brokerAgentsKpiSnapshotProvider);
  ref.invalidate(brokerOpenTasksCountProvider);
  ref.invalidate(brokerDashboardAlertsProvider);
  ref.invalidate(managerEscalationsProvider);
  ref.invalidate(resurrectionQueueProvider);
  ref.invalidate(brokerRevenueDashboardSnapshotProvider);
}
