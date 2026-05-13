import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';

/// Danışman / yönetici çağrı listeleri için hızlı karar filtresi (istemci tarafı, ek sorgu yok).
enum CallSurfaceQuickFilter {
  all,
  today,
  unanswered,
  callback,
  reached,
  /// Sonuç bekleyen veya kayıt süreci — operasyonel “sıcak” kuyruk.
  hot,
  /// Son 48 saat içinde oluşturulmuş kayıtlar.
  fresh,
}

abstract final class CallSurfaceQuickFilterLogic {
  CallSurfaceQuickFilterLogic._();

  static DateTime startOfTodayLocal() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String? outcomeCode(Map<String, dynamic> data) =>
      (data['outcome'] as String?)?.trim().isNotEmpty == true
          ? data['outcome'] as String
          : (data['callOutcome'] as String?)?.trim();

  static bool matchesFirestoreDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    CallSurfaceQuickFilter f,
  ) {
    if (f == CallSurfaceQuickFilter.all) return true;
    final data = doc.data();
    final created = CrmCallRecordHelpers.createdAtOf(data);
    final oc = outcomeCode(data) ?? '';
    final startDay = startOfTodayLocal();

    switch (f) {
      case CallSurfaceQuickFilter.all:
        return true;
      case CallSurfaceQuickFilter.today:
        return created != null && !created.isBefore(startDay);
      case CallSurfaceQuickFilter.unanswered:
        return oc == 'missed' ||
            oc == 'no_answer' ||
            oc == 'busy' ||
            oc == 'failed';
      case CallSurfaceQuickFilter.callback:
        return oc == 'callback_scheduled';
      case CallSurfaceQuickFilter.reached:
        return oc == 'reached' ||
            oc == 'connected' ||
            oc == 'completed' ||
            oc == 'appointment_set' ||
            oc == 'offer_sent';
      case CallSurfaceQuickFilter.hot:
        return CrmCallRecordHelpers.isHandoffPending(data) ||
            !CrmCallRecordHelpers.hasCaptureCompleted(data);
      case CallSurfaceQuickFilter.fresh:
        if (created == null) return false;
        final age = DateTime.now().difference(created);
        return age.inHours <= 48;
    }
  }

  static bool matchesLocalRecord(LocalCallRecord r, CallSurfaceQuickFilter f) {
    if (f == CallSurfaceQuickFilter.all) return true;
    final created = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
    final startDay = startOfTodayLocal();
    final oc = (r.outcome ?? '').trim();

    switch (f) {
      case CallSurfaceQuickFilter.all:
        return true;
      case CallSurfaceQuickFilter.today:
        return !created.isBefore(startDay);
      case CallSurfaceQuickFilter.unanswered:
        return oc == 'missed' ||
            oc == 'no_answer' ||
            oc == 'busy' ||
            oc == 'failed';
      case CallSurfaceQuickFilter.callback:
        return oc == 'callback_scheduled';
      case CallSurfaceQuickFilter.reached:
        return oc == 'reached' ||
            oc == 'connected' ||
            oc == 'completed' ||
            oc == 'appointment_set' ||
            oc == 'offer_sent';
      case CallSurfaceQuickFilter.hot:
        return oc == 'handoff_pending' || !r.hasQuickCapturePayload;
      case CallSurfaceQuickFilter.fresh:
        final age = DateTime.now().difference(created);
        return age.inHours <= 48;
    }
  }
}

/// Üst rehber şeridi için hafif istatistik (tek geçişte hesaplanabilir).
class CallSurfaceListStats {
  const CallSurfaceListStats({
    required this.today,
    required this.pendingCapture,
    required this.unanswered,
  });

  final int today;
  final int pendingCapture;
  final int unanswered;

  static CallSurfaceListStats fromFirestoreDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var today = 0;
    var pending = 0;
    var unanswered = 0;
    final start = CallSurfaceQuickFilterLogic.startOfTodayLocal();
    for (final d in docs) {
      final data = d.data();
      final created = CrmCallRecordHelpers.createdAtOf(data);
      if (created != null && !created.isBefore(start)) today++;
      if (!CrmCallRecordHelpers.hasCaptureCompleted(data) ||
          CrmCallRecordHelpers.isHandoffPending(data)) {
        pending++;
      }
      final oc = CallSurfaceQuickFilterLogic.outcomeCode(data) ?? '';
      if (oc == 'missed' || oc == 'no_answer') unanswered++;
    }
    return CallSurfaceListStats(
      today: today,
      pendingCapture: pending,
      unanswered: unanswered,
    );
  }

  /// Danışman listesi: Firestore + bu cihazdaki yerel taslaklar için birleşik özet.
  static CallSurfaceListStats blendedConsultant({
    required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required Iterable<LocalCallRecord> locals,
  }) {
    final fs = fromFirestoreDocs(docs);
    final start = CallSurfaceQuickFilterLogic.startOfTodayLocal();
    var localToday = 0;
    var localPending = 0;
    for (final r in locals) {
      final c = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
      if (!c.isBefore(start)) localToday++;
      if (!r.hasQuickCapturePayload) localPending++;
    }
    return CallSurfaceListStats(
      today: fs.today + localToday,
      pendingCapture: fs.pendingCapture + localPending,
      unanswered: fs.unanswered,
    );
  }
}
