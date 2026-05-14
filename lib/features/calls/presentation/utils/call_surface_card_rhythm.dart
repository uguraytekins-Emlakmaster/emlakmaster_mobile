import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';

/// Liste kartlarında çok hafif görsel ritim — tek aile, düşük gürültü.
enum CallSurfaceCardRhythm {
  standard,
  linkedCustomer,
  unknownIdentity,
  callbackQueue,
  attention,
}

abstract final class CallSurfaceCardRhythmLogic {
  CallSurfaceCardRhythmLogic._();

  static String? _outcome(Map<String, dynamic> data) =>
      (data['outcome'] as String?)?.trim().isNotEmpty == true
          ? data['outcome'] as String
          : (data['callOutcome'] as String?)?.trim();

  static CallSurfaceCardRhythm forFirestore(Map<String, dynamic> data) {
    final oc = _outcome(data) ?? '';
    if (oc == 'callback_scheduled') {
      return CallSurfaceCardRhythm.callbackQueue;
    }
    if (!CrmCallRecordHelpers.hasCaptureCompleted(data) ||
        CrmCallRecordHelpers.isHandoffPending(data)) {
      return CallSurfaceCardRhythm.attention;
    }
    final cid = CrmCallRecordHelpers.customerIdOf(data);
    if (cid == null) {
      return CallSurfaceCardRhythm.unknownIdentity;
    }
    return CallSurfaceCardRhythm.linkedCustomer;
  }

  static CallSurfaceCardRhythm forLocalDraft(LocalCallRecord r) {
    final oc = (r.outcome ?? '').trim();
    if (oc == 'callback_scheduled') {
      return CallSurfaceCardRhythm.callbackQueue;
    }
    if (!r.hasQuickCapturePayload) {
      return CallSurfaceCardRhythm.attention;
    }
    if (r.customerId == null || r.customerId!.trim().isEmpty) {
      return CallSurfaceCardRhythm.unknownIdentity;
    }
    return CallSurfaceCardRhythm.linkedCustomer;
  }
}

/// Sessiz öncelik çubuğu — ince dikey vurgu.
abstract final class CallSurfacePriorityMarkers {
  CallSurfacePriorityMarkers._();

  static bool railForFirestore(Map<String, dynamic> data) {
    final oc = (data['outcome'] as String?)?.trim() ?? '';
    if (oc == 'callback_scheduled') return true;
    if (CrmCallRecordHelpers.isHandoffPending(data)) return true;
    if (!CrmCallRecordHelpers.hasCaptureCompleted(data)) return true;
    return false;
  }

  static bool railForLocal(LocalCallRecord r) {
    if ((r.outcome ?? '').trim() == 'callback_scheduled') return true;
    if (!r.hasQuickCapturePayload) return true;
    return false;
  }
}
