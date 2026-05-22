import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';

/// Çağrı listesi sıralama — mockup: “Sırala: Son arama”.
enum CallListSortMode {
  lastCall,
  oldestFirst,
  unansweredFirst,
}

extension CallListSortModeLabels on CallListSortMode {
  String get labelTr {
    switch (this) {
      case CallListSortMode.lastCall:
        return 'Son arama';
      case CallListSortMode.oldestFirst:
        return 'En eski';
      case CallListSortMode.unansweredFirst:
        return 'Cevapsız önce';
    }
  }
}

abstract final class CallListSortLogic {
  CallListSortLogic._();

  static int _docTimeMs(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final dt = CrmCallRecordHelpers.createdAtOf(doc.data());
    return dt?.millisecondsSinceEpoch ?? 0;
  }

  static void sortFirestoreDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    CallListSortMode mode,
  ) {
    docs.sort((a, b) {
      switch (mode) {
        case CallListSortMode.lastCall:
          return _docTimeMs(b).compareTo(_docTimeMs(a));
        case CallListSortMode.oldestFirst:
          return _docTimeMs(a).compareTo(_docTimeMs(b));
        case CallListSortMode.unansweredFirst:
          final am = CrmCallRecordHelpers.isMissedOutcome(a.data()) ? 0 : 1;
          final bm = CrmCallRecordHelpers.isMissedOutcome(b.data()) ? 0 : 1;
          final cmp = am.compareTo(bm);
          if (cmp != 0) return cmp;
          return _docTimeMs(b).compareTo(_docTimeMs(a));
      }
    });
  }

  static void sortLocalRecords(List<LocalCallRecord> locals, CallListSortMode mode) {
    locals.sort((a, b) {
      switch (mode) {
        case CallListSortMode.lastCall:
          return b.createdAt.compareTo(a.createdAt);
        case CallListSortMode.oldestFirst:
          return a.createdAt.compareTo(b.createdAt);
        case CallListSortMode.unansweredFirst:
          final am = _localMissed(a) ? 0 : 1;
          final bm = _localMissed(b) ? 0 : 1;
          final cmp = am.compareTo(bm);
          if (cmp != 0) return cmp;
          return b.createdAt.compareTo(a.createdAt);
      }
    });
  }

  static bool _localMissed(LocalCallRecord r) {
    final oc = (r.outcome ?? '').toLowerCase();
    return oc == 'missed' ||
        oc == 'no_answer' ||
        oc == 'busy' ||
        oc == 'failed';
  }
}
