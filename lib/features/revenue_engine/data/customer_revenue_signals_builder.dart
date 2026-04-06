import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/customer_signal_inputs.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/follow_up_recommendation_engine.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/high_value_ranking.dart'
    show computeValueScore;
import 'package:emlakmaster_mobile/features/revenue_engine/domain/lead_score_engine.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Firestore çağrı dokümanları + CRM müşteri + Hive yerel özetlerinden sinyal üretir.
Map<String, CustomerRevenueSignals> buildCustomerRevenueSignalsMap({
  required List<CustomerEntity> customers,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> callDocs,
  required List<LocalCallRecord> localCalls,
  required Set<String> openTaskCustomerIds,
  required Set<String> syncDelayedRiskCustomerIds,
  required DateTime now,
}) {
  final byCustomerCalls = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
  for (final d in callDocs) {
    final cid = CrmCallRecordHelpers.customerIdOf(d.data());
    if (cid == null) continue;
    byCustomerCalls.putIfAbsent(cid, () => []).add(d);
  }
  for (final list in byCustomerCalls.values) {
    list.sort((a, b) {
      final at = CrmCallRecordHelpers.createdAtOf(a.data()) ?? DateTime(1970);
      final bt = CrmCallRecordHelpers.createdAtOf(b.data()) ?? DateTime(1970);
      return bt.compareTo(at);
    });
  }

  final localsByCustomer = <String, List<LocalCallRecord>>{};
  for (final r in localCalls) {
    final c = r.customerId?.trim();
    if (c == null || c.isEmpty) continue;
    localsByCustomer.putIfAbsent(c, () => []).add(r);
  }

  final out = <String, CustomerRevenueSignals>{};
  for (final c in customers) {
    final id = c.id;
    final docs = byCustomerCalls[id] ?? const [];
    final lastDoc = docs.isEmpty ? null : docs.first;
    final lastCode = lastDoc != null
        ? normalizeCallOutcomeCode(lastDoc.data())
        : null;

    final lastContact = _lastContactAt(c, docs, localsByCustomer[id]);
    final fsCount = docs.length;
    final noAns = _countNoAnswerRecent(docs, now);
    final hasAppt = docs.any((d) => isAppointment(normalizeCallOutcomeCode(d.data())));
    final offerCrm = c.offersCount > 0;
    final localUnsynced =
        (localsByCustomer[id] ?? const []).any((r) => !r.isSynced);

    final in_ = CustomerSignalInputs(
      customerId: id,
      lastContactAt: lastContact,
      lastCallOutcomeCode: lastCode,
      firestoreCallCount: fsCount,
      noAnswerCountRecent: noAns,
      hasOfferFromCrm: offerCrm,
      hasAppointmentFromCalls: hasAppt,
      localUnsyncedWithCustomer: localUnsynced,
      openManualTask: openTaskCustomerIds.contains(id),
    );

    final score = computeLeadScore(in_, now);
    final band = bandFromScore(score);
    final follow = computeFollowUpRecommendation(
      in_: in_,
      leadScore: score,
      band: band,
      now: now,
    );
    final valueScore = computeValueScore(
      leadScore: score,
      firestoreCallCount: fsCount,
      lastContactAt: lastContact,
      now: now,
    );

    out[id] = CustomerRevenueSignals(
      customerId: id,
      leadScore: score,
      band: band,
      valueScore: valueScore,
      nextAction: follow.action,
      nextActionTime: follow.at,
      recommendationSuppressed: follow.suppressed,
      syncDelayedRisk: syncDelayedRiskCustomerIds.contains(id),
      suppressionReason: follow.reason,
    );
  }
  return out;
}

DateTime? _lastContactAt(
  CustomerEntity c,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  List<LocalCallRecord>? locals,
) {
  DateTime? best = c.lastInteractionAt;
  if (docs.isNotEmpty) {
    final t = CrmCallRecordHelpers.createdAtOf(docs.first.data());
    if (t != null && (best == null || t.isAfter(best))) best = t;
  }
  if (locals != null) {
    for (final r in locals) {
      final t = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
      if (best == null || t.isAfter(best)) best = t;
    }
  }
  return best;
}

int _countNoAnswerRecent(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  DateTime now,
) {
  final cutoff = now.subtract(const Duration(days: 14));
  var n = 0;
  for (final d in docs) {
    final t = CrmCallRecordHelpers.createdAtOf(d.data());
    if (t == null || t.isBefore(cutoff)) continue;
    final code = normalizeCallOutcomeCode(d.data());
    if (isNoAnswer(code)) n++;
  }
  return n;
}

ConsultantActivityRollup buildRollupForAdvisor({
  required String advisorId,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> callDocs,
  required int missedFollowUps,
  required int inactivityDays,
}) {
  var success = 0;
  var appt = 0;
  var offers = 0;
  for (final d in callDocs) {
    final code = normalizeCallOutcomeCode(d.data());
    if (isSuccessfulReach(code)) success++;
    if (isAppointment(code)) appt++;
    if (isOffer(code)) offers++;
  }
  return ConsultantActivityRollup(
    advisorId: advisorId,
    callsMade: callDocs.length,
    successfulCalls: success,
    appointmentsCreated: appt,
    offersRecorded: offers,
    missedFollowUps: missedFollowUps,
    inactivityPenaltyDays: inactivityDays,
  );
}

RevenueDashboardSnapshot buildRevenueDashboardSnapshot({
  required Map<String, CustomerRevenueSignals> signals,
  required Map<String, CustomerEntity> customerById,
  required int selfPerformanceScore,
  required List<ConsultantLeaderboardEntry> leaderboard,
  required DateTime now,
}) {
  final rows = <CustomerRevenueRow>[];
  for (final e in signals.entries) {
    final c = customerById[e.key];
    if (c == null) continue;
    final s = e.value;
    rows.add(
      CustomerRevenueRow(
        customerId: c.id,
        displayName: c.fullName ?? 'Müşteri',
        leadScore: s.leadScore,
        valueScore: s.valueScore,
        band: s.band,
        nextAction: s.nextAction,
        nextActionTime: s.nextActionTime,
        syncDelayedRisk: s.syncDelayedRisk,
      ),
    );
  }

  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
  final hotPool = rows.where((r) => r.band == RevenueLeadBand.hot).toList();
  hotPool.sort((a, b) => b.valueScore.compareTo(a.valueScore));
  final hot = hotPool.take(5).toList();

  bool isDueToday(DateTime t) =>
      !t.isBefore(startOfDay) && !t.isAfter(endOfDay);
  final today = rows
      .where((r) => isDueToday(r.nextActionTime))
      .where((r) => r.nextAction != RevenueNextActionKind.wait)
      .toList()
    ..sort((a, b) => a.nextActionTime.compareTo(b.nextActionTime));
  final todayLimited = today.take(8).toList();

  final atRiskPool = rows.where((r) => r.syncDelayedRisk).toList()
    ..sort((a, b) => b.valueScore.compareTo(a.valueScore));
  final atRisk = atRiskPool.take(8).toList();

  return RevenueDashboardSnapshot(
    hotCustomers: hot,
    actionToday: todayLimited,
    atRiskSync: atRisk,
    selfPerformanceScore: selfPerformanceScore,
    leaderboard: leaderboard,
  );
}
