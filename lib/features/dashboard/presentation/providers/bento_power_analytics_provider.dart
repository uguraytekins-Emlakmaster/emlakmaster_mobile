import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/war_room/data/war_room_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BentoPowerAnalyticsSnapshot {
  const BentoPowerAnalyticsSnapshot({
    required this.callsCount,
    required this.dealsCount,
    required this.missedCalls,
  });

  final int callsCount;
  final int dealsCount;
  final int missedCalls;

  static const zero = BentoPowerAnalyticsSnapshot(
    callsCount: 0,
    dealsCount: 0,
    missedCalls: 0,
  );
}

final dashboardCallsCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirestoreService.callsCountStream();
});

final dashboardDealsCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirestoreService.dealsCountStream();
});

int _missedFromAgents(
  AsyncValue<QuerySnapshot<Map<String, dynamic>>> agents,
) {
  return agents.when(
    data: (snap) {
      var missed = 0;
      for (final doc in snap.docs) {
        missed += (doc.data()['missedCalls'] as num?)?.toInt() ?? 0;
      }
      return missed;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
}

/// Power Analytics kartı — paralel Riverpod (iç içe StreamBuilder yok).
final bentoPowerAnalyticsSnapshotProvider =
    Provider.autoDispose<AsyncValue<BentoPowerAnalyticsSnapshot>>((ref) {
  final calls = ref.watch(dashboardCallsCountProvider);
  final deals = ref.watch(dashboardDealsCountProvider);
  final agents = ref.watch(agentsSnapshotProvider);

  if (calls.hasError && !calls.hasValue) {
    return AsyncError(calls.error!, calls.stackTrace!);
  }
  if (deals.hasError && !deals.hasValue) {
    return AsyncError(deals.error!, deals.stackTrace!);
  }
  if (!calls.hasValue || !deals.hasValue) {
    return const AsyncLoading();
  }

  return AsyncData(
    BentoPowerAnalyticsSnapshot(
      callsCount: calls.requireValue,
      dealsCount: deals.requireValue,
      missedCalls: _missedFromAgents(agents),
    ),
  );
});
