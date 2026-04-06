import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_wide_customers_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/sync_delayed_risk_customer_ids_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
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

/// Son 500 çağrı (ofis gelir özeti için müşteri kümesine süzülür).
final brokerCallsDocumentsProvider =
    StreamProvider.autoDispose<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return FirestoreService.callsStream().map((s) => s.docs);
});

/// Ofis müşterileri için gelir motoru haritası (yönetici paneli).
final officeCustomerRevenueSignalsMapProvider =
    Provider.family<Map<String, CustomerRevenueSignals>, String>((ref, officeId) {
  if (officeId.isEmpty) return {};
  final customersAsync = ref.watch(officeWideCustomerListProvider(officeId));
  final allDocs = ref.watch(brokerCallsDocumentsProvider).valueOrNull ?? [];
  final locals = ref.watch(localCallRecordsStreamProvider).valueOrNull ?? [];
  final syncRisk = ref.watch(syncDelayedRiskCustomerIdsProvider);

  return customersAsync.maybeWhen(
    data: (customers) {
      if (customers.isEmpty) return <String, CustomerRevenueSignals>{};
      final ids = customers.map((c) => c.id).toSet();
      final filtered = allDocs.where((d) {
        final cid = CrmCallRecordHelpers.customerIdOf(d.data());
        return cid != null && ids.contains(cid);
      }).toList();
      return buildCustomerRevenueSignalsMap(
        customers: customers,
        callDocs: filtered,
        localCalls: locals,
        openTaskCustomerIds: const {},
        syncDelayedRiskCustomerIds: syncRisk,
        now: DateTime.now(),
      );
    },
    orElse: () => <String, CustomerRevenueSignals>{},
  );
});

/// Yönetici dashboard’u: ofis müşterileri + son çağrılar üzerinden özet + danışman sıralaması.
final brokerRevenueDashboardSnapshotProvider = Provider<RevenueDashboardSnapshot>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  if (uid.isEmpty) {
    return const RevenueDashboardSnapshot(
      hotCustomers: [],
      actionToday: [],
      atRiskSync: [],
      selfPerformanceScore: 0,
      leaderboard: [],
    );
  }
  final officeId = ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId ?? '';
  if (officeId.isEmpty) {
    return const RevenueDashboardSnapshot(
      hotCustomers: [],
      actionToday: [],
      atRiskSync: [],
      selfPerformanceScore: 0,
      leaderboard: [],
    );
  }

  final signals = ref.watch(officeCustomerRevenueSignalsMapProvider(officeId));
  final customersAsync = ref.watch(officeWideCustomerListProvider(officeId));
  final allDocs = ref.watch(brokerCallsDocumentsProvider).valueOrNull ?? [];

  return customersAsync.maybeWhen(
    data: (customers) {
      final byId = {for (final c in customers) c.id: c};
      final officeAdvisorIds = customers
          .map((c) => c.assignedAdvisorId)
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toSet();

      final filteredForRollup = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final customerIds = customers.map((c) => c.id).toSet();
      for (final d in allDocs) {
        final cid = CrmCallRecordHelpers.customerIdOf(d.data());
        if (cid == null || !customerIds.contains(cid)) continue;
        filteredForRollup.add(d);
      }

      final byAdvisor = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      for (final d in filteredForRollup) {
        final aid = CrmCallRecordHelpers.agentIdOf(d.data());
        if (aid.isEmpty || !officeAdvisorIds.contains(aid)) continue;
        byAdvisor.putIfAbsent(aid, () => []).add(d);
      }

      int scoreForDocs(String advisorId, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
        if (docs.isEmpty) return 0;
        final rollup = buildRollupForAdvisor(
          advisorId: advisorId,
          callDocs: docs,
          missedFollowUps: 0,
          inactivityDays: 0,
        );
        return computeConsultantPerformanceScore(rollup);
      }

      final sortedAdvisors = byAdvisor.entries.toList()
        ..sort((a, b) => scoreForDocs(b.key, b.value).compareTo(scoreForDocs(a.key, a.value)));

      final leaderboard = <ConsultantLeaderboardEntry>[];
      var rank = 1;
      for (final e in sortedAdvisors.take(8)) {
        final sc = scoreForDocs(e.key, e.value);
        final short = e.key.length >= 4 ? e.key.substring(e.key.length - 4) : e.key;
        leaderboard.add(
          ConsultantLeaderboardEntry(
            advisorId: e.key,
            displayLabel: '···$short',
            performanceScore: sc,
            rank: rank++,
          ),
        );
      }

      return buildRevenueDashboardSnapshot(
        signals: signals,
        customerById: byId,
        selfPerformanceScore: 0,
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
