import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/sync_delayed_risk_customer_ids_provider.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/data/customer_revenue_signals_builder.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/consultant_performance_engine.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Açık görevli müşteri ID’leri + gecikmiş görev sayısı (tek `tasks` dinleyicisi).
class AdvisorTasksMeta {
  const AdvisorTasksMeta({
    required this.openCustomerIds,
    required this.overdueCount,
  });

  final Set<String> openCustomerIds;
  final int overdueCount;
}

final advisorTasksMetaProvider = StreamProvider<AdvisorTasksMeta>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value(const AdvisorTasksMeta(openCustomerIds: {}, overdueCount: 0));
  }
  return FirestoreService.tasksByAdvisorStream(uid).map((snap) {
    final open = <String>{};
    var overdue = 0;
    final now = DateTime.now();
    for (final d in snap.docs) {
      final data = d.data();
      final done = data['done'] == true || data['completed'] == true;
      if (done) continue;
      final dueRaw = data['dueAt'] ?? data['dueDate'];
      DateTime? dueAt;
      if (dueRaw is Timestamp) {
        dueAt = dueRaw.toDate();
      } else if (dueRaw is DateTime) {
        dueAt = dueRaw;
      }
      if (dueAt != null && dueAt.isBefore(now)) overdue++;
      final cid = data['customerId'] as String?;
      if (cid != null && cid.trim().isNotEmpty) open.add(cid.trim());
    }
    return AdvisorTasksMeta(openCustomerIds: open, overdueCount: overdue);
  });
});

/// Müşteri başına önbelleklenmiş gelir motoru sinyalleri (tek recomputation).
final customerRevenueSignalsMapProvider =
    Provider<Map<String, CustomerRevenueSignals>>((ref) {
  final customersAsync = ref.watch(customerListForAgentProvider);
  final calls = ref.watch(consultantCallsStreamProvider).valueOrNull ?? [];
  final locals = ref.watch(localCallRecordsStreamProvider).valueOrNull ?? [];
  final tasksMeta = ref.watch(advisorTasksMetaProvider).valueOrNull;
  final syncRisk = ref.watch(syncDelayedRiskCustomerIdsProvider);

  return customersAsync.maybeWhen(
    data: (customers) => buildCustomerRevenueSignalsMap(
      customers: customers,
      callDocs: calls,
      localCalls: locals,
      openTaskCustomerIds: tasksMeta?.openCustomerIds ?? {},
      syncDelayedRiskCustomerIds: syncRisk,
      now: DateTime.now(),
    ),
    orElse: () => <String, CustomerRevenueSignals>{},
  );
});

/// Danışman performans skoru — çağrı + görev tek yerde; snapshot tekrar sorgu izlemez.
final advisorPerformanceScoreProvider = Provider<int>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  if (uid.isEmpty) return 0;
  final calls = ref.watch(consultantCallsStreamProvider).valueOrNull ?? [];
  final tasksMeta = ref.watch(advisorTasksMetaProvider).valueOrNull;
  final rollup = buildRollupForAdvisor(
    advisorId: uid,
    callDocs: calls,
    missedFollowUps: tasksMeta?.overdueCount ?? 0,
    inactivityDays: 0,
  );
  return computeConsultantPerformanceScore(rollup);
});

/// Özetim kartları: yalnızca sinyal haritası + müşteri listesi + performans (çift döngü yok).
final revenueDashboardSnapshotProvider =
    Provider<RevenueDashboardSnapshot>((ref) {
  final signals = ref.watch(customerRevenueSignalsMapProvider);
  final customersAsync = ref.watch(customerListForAgentProvider);
  final perf = ref.watch(advisorPerformanceScoreProvider);
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';

  return customersAsync.maybeWhen(
    data: (customers) {
      final byId = {for (final c in customers) c.id: c};
      final leaderboard = <ConsultantLeaderboardEntry>[
        if (uid.isNotEmpty)
          ConsultantLeaderboardEntry(
            advisorId: uid,
            displayLabel: 'Sen',
            performanceScore: perf,
            rank: 1,
          ),
      ];
      return buildRevenueDashboardSnapshot(
        signals: signals,
        customerById: byId,
        selfPerformanceScore: perf,
        leaderboard: leaderboard,
        now: DateTime.now(),
      );
    },
    orElse: () => const RevenueDashboardSnapshot(
      hotCustomers: [],
      actionToday: [],
      atRiskSync: [],
      selfPerformanceScore: 0,
      leaderboard: [],
    ),
  );
});

/// Tek müşteri sinyali (liste satırında `select` ile kullanın).
CustomerRevenueSignals? customerRevenueSignalsFor(
  Map<String, CustomerRevenueSignals> map,
  CustomerEntity customer,
) {
  return map[customer.id];
}
