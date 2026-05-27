import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_alerts_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/manager_escalations_provider.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mevcut broker akışlarını birleştirir; ek Firestore sorgusu yok.
final adminCommandSnapshotProvider =
    Provider.autoDispose<AsyncValue<AdminCommandSnapshot>>((ref) {
  final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
  if (!role.isManagerTier) {
    return const AsyncValue.data(AdminCommandSnapshot.empty);
  }

  final kpiAsync = ref.watch(brokerAgentsKpiSnapshotProvider);
  final tasksAsync = ref.watch(brokerOpenTasksCountProvider);
  final alertsAsync = ref.watch(brokerDashboardAlertsProvider);
  final escAsync = ref.watch(managerEscalationsProvider);
  final followUpAsync = ref.watch(resurrectionQueueProvider);
  final revenueSnap = ref.watch(brokerRevenueDashboardSnapshotProvider);
  final platforms = ref.watch(platformListProvider);

  if (kpiAsync.isLoading ||
      tasksAsync.isLoading ||
      alertsAsync.isLoading ||
      escAsync.isLoading ||
      followUpAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (kpiAsync.hasError) {
    return AsyncValue.error(kpiAsync.error!, kpiAsync.stackTrace ?? StackTrace.empty);
  }
  if (tasksAsync.hasError) {
    return AsyncValue.error(tasksAsync.error!, tasksAsync.stackTrace ?? StackTrace.empty);
  }
  if (alertsAsync.hasError) {
    return AsyncValue.error(alertsAsync.error!, alertsAsync.stackTrace ?? StackTrace.empty);
  }
  if (escAsync.hasError) {
    return AsyncValue.error(escAsync.error!, escAsync.stackTrace ?? StackTrace.empty);
  }
  if (followUpAsync.hasError) {
    return AsyncValue.error(
      followUpAsync.error!,
      followUpAsync.stackTrace ?? StackTrace.empty,
    );
  }

  final kpi = kpiAsync.value ?? BrokerAgentsKpiSnapshot.empty;
  final alerts = alertsAsync.value ?? [];
  final escalations = escAsync.value ?? [];
  final followUp = followUpAsync.value ?? [];

  final health = computeAdminOfficeHealthSummary(
    activeAdvisors: kpi.activeAdvisors,
    openTasks: tasksAsync.value ?? 0,
    liveCalls: kpi.activeCalls,
    missedCalls: kpi.missedCalls,
    alerts: alerts,
    escalations: escalations,
    followUpQueue: followUp.length,
    setupPending: countIntegrationSetupPending(platforms),
    syncRisk: revenueSnap.atRiskSync.length,
  );

  final urgent = buildAdminCommandUrgentItems(
    health: health,
    alerts: alerts,
    escalations: escalations,
  );

  return AsyncValue.data(
    AdminCommandSnapshot(health: health, urgentItems: urgent),
  );
});
