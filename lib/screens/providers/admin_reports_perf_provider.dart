import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminReportsPerfSnapshot {
  const AdminReportsPerfSnapshot({
    required this.hasSummaries,
    required this.hasDeals,
  });

  final bool hasSummaries;
  final bool hasDeals;

  bool get hasAnyData => hasSummaries || hasDeals;
}

final adminCallSummariesSampleProvider = StreamProvider.autoDispose<
    QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirestoreService.callSummariesSampleStream();
});

final adminDealsSampleProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirestoreService.dealsSampleStream();
});

/// Raporlar performans bölümü — paralel stream (iç içe StreamBuilder yok).
final adminReportsPerfProvider =
    Provider.autoDispose<AsyncValue<AdminReportsPerfSnapshot>>((ref) {
  final summaries = ref.watch(adminCallSummariesSampleProvider);
  final deals = ref.watch(adminDealsSampleProvider);

  if (summaries.hasError && !summaries.hasValue) {
    return AsyncError(summaries.error!, summaries.stackTrace!);
  }
  if (deals.hasError && !deals.hasValue) {
    return AsyncError(deals.error!, deals.stackTrace!);
  }
  if (!summaries.hasValue || !deals.hasValue) {
    return const AsyncLoading();
  }

  return AsyncData(
    AdminReportsPerfSnapshot(
      hasSummaries: summaries.requireValue.docs.isNotEmpty,
      hasDeals: deals.requireValue.docs.isNotEmpty,
    ),
  );
});
