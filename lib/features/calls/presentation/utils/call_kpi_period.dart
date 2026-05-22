import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';

/// Çağrı merkezi KPI sayıları.
class CallRecordKpiStats {
  const CallRecordKpiStats({
    required this.total,
    required this.incoming,
    required this.outgoing,
    required this.answered,
    required this.missed,
  });

  final int total;
  final int incoming;
  final int outgoing;
  final int answered;
  final int missed;

  static CallRecordKpiStats fromFirestoreDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var incoming = 0;
    var outgoing = 0;
    var missed = 0;
    var answered = 0;
    for (final d in docs) {
      final data = d.data();
      final direction =
          (data['direction'] as String? ?? 'outgoing').toLowerCase();
      if (direction == 'incoming') {
        incoming++;
      } else {
        outgoing++;
      }
      if (CrmCallRecordHelpers.isMissedOutcome(data)) {
        missed++;
      } else if (CrmCallRecordHelpers.isAnsweredOutcome(data)) {
        answered++;
      }
    }
    return CallRecordKpiStats(
      total: docs.length,
      incoming: incoming,
      outgoing: outgoing,
      answered: answered,
      missed: missed,
    );
  }
}

/// KPI dönem seçimi — “Bu ay” gerçek tarih filtresi ile eşleşir.
enum CallKpiPeriod {
  thisMonth,
  allTime,
}

extension CallKpiPeriodLabels on CallKpiPeriod {
  String get labelTr {
    switch (this) {
      case CallKpiPeriod.thisMonth:
        return 'Bu ay';
      case CallKpiPeriod.allTime:
        return 'Tüm kayıtlar';
    }
  }
}

class CallKpiPeriodSnapshot {
  const CallKpiPeriodSnapshot({
    required this.current,
    required this.previous,
    required this.period,
  });

  final CallRecordKpiStats current;
  final CallRecordKpiStats previous;
  final CallKpiPeriod period;

  int? percentDelta(int current, int previous) {
    if (previous <= 0) return current > 0 ? 100 : null;
    return (((current - previous) / previous) * 100).round();
  }
}

abstract final class CallKpiPeriodLogic {
  CallKpiPeriodLogic._();

  static DateTime _startOfThisMonthLocal() {
    final n = DateTime.now();
    return DateTime(n.year, n.month);
  }

  static DateTime _startOfPreviousMonthLocal() {
    final start = _startOfThisMonthLocal();
    return DateTime(start.year, start.month - 1);
  }

  static bool _docInRange(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    DateTime start,
    DateTime? endExclusive,
  ) {
    final dt = CrmCallRecordHelpers.createdAtOf(doc.data());
    if (dt == null) return false;
    if (dt.isBefore(start)) return false;
    if (endExclusive != null && !dt.isBefore(endExclusive)) return false;
    return true;
  }

  static Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> filterDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    CallKpiPeriod period,
  ) {
    if (period == CallKpiPeriod.allTime) return docs;
    final start = _startOfThisMonthLocal();
    return docs.where((d) => _docInRange(d, start, null));
  }

  static CallKpiPeriodSnapshot snapshotFromDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    CallKpiPeriod period,
  ) {
    if (period == CallKpiPeriod.allTime) {
      final stats = CallRecordKpiStats.fromFirestoreDocs(docs);
      return CallKpiPeriodSnapshot(
        current: stats,
        previous: const CallRecordKpiStats(
          total: 0,
          incoming: 0,
          outgoing: 0,
          answered: 0,
          missed: 0,
        ),
        period: period,
      );
    }
    final monthStart = _startOfThisMonthLocal();
    final prevStart = _startOfPreviousMonthLocal();
    final currentDocs =
        docs.where((d) => _docInRange(d, monthStart, null)).toList();
    final previousDocs = docs
        .where((d) => _docInRange(d, prevStart, monthStart))
        .toList();
    return CallKpiPeriodSnapshot(
      current: CallRecordKpiStats.fromFirestoreDocs(currentDocs),
      previous: CallRecordKpiStats.fromFirestoreDocs(previousDocs),
      period: period,
    );
  }
}
