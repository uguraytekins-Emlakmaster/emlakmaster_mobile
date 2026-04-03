import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/domain/broker_dashboard_intelligence_summary.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_alerts_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_smart_task_suggestions_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/execution_reminders_providers.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/manager_escalations_provider.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_wide_customers_stream_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mevcut broker veri akışlarını birleştirir; ek sorgu yok.
final brokerDashboardIntelligenceSummaryProvider =
    Provider.autoDispose<AsyncValue<BrokerDashboardIntelligenceLines>>((ref) {
  final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
  if (!role.isManagerTier) {
    return const AsyncValue.data(BrokerDashboardIntelligenceLines.empty);
  }
  final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  if (uid.isEmpty) {
    return const AsyncValue.data(BrokerDashboardIntelligenceLines.empty);
  }
  final officeId =
      ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId ?? '';
  if (officeId.isEmpty) {
    return const AsyncValue.data(BrokerDashboardIntelligenceLines.empty);
  }

  final alertsAsync = ref.watch(brokerDashboardAlertsProvider);
  final customersAsync = ref.watch(officeWideCustomerListProvider(officeId));
  final escalationsAsync = ref.watch(managerEscalationsProvider);
  final tasksAsync = ref.watch(brokerSmartTaskSuggestionsProvider);
  final remindersAsync = ref.watch(brokerExecutionRemindersProvider);

  if (alertsAsync.isLoading ||
      customersAsync.isLoading ||
      escalationsAsync.isLoading ||
      tasksAsync.isLoading ||
      remindersAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (alertsAsync.hasError) {
    return AsyncValue.error(
      alertsAsync.error!,
      alertsAsync.stackTrace ?? StackTrace.empty,
    );
  }
  if (customersAsync.hasError) {
    return AsyncValue.error(
      customersAsync.error!,
      customersAsync.stackTrace ?? StackTrace.empty,
    );
  }
  if (escalationsAsync.hasError) {
    return AsyncValue.error(
      escalationsAsync.error!,
      escalationsAsync.stackTrace ?? StackTrace.empty,
    );
  }
  if (tasksAsync.hasError) {
    return AsyncValue.error(
      tasksAsync.error!,
      tasksAsync.stackTrace ?? StackTrace.empty,
    );
  }
  if (remindersAsync.hasError) {
    return AsyncValue.error(
      remindersAsync.error!,
      remindersAsync.stackTrace ?? StackTrace.empty,
    );
  }

  final lines = buildBrokerDashboardIntelligenceSummary(
    alerts: alertsAsync.value ?? [],
    escalations: escalationsAsync.value ?? [],
    smartTasks: tasksAsync.value ?? [],
    executionReminders: remindersAsync.value ?? [],
    customers: customersAsync.value ?? [],
  );
  if (kDebugMode) {
    final a = alertsAsync.value ?? [];
    final e = escalationsAsync.value ?? [];
    final t = tasksAsync.value ?? [];
    final r = remindersAsync.value ?? [];
    final c = customersAsync.value ?? [];
    AppLogger.d(
      'Broker intel summary: alerts=${a.length} esc=${e.length} '
      'tasks=${t.length} rem=${r.length} customers=${c.length} hasAny=${lines.hasAny}',
    );
  }
  return AsyncValue.data(lines);
});
