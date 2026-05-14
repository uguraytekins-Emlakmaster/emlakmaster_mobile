import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';

/// Tek satırlık, gerçek veriye dayalı hafıza ipucu.
abstract final class CallCardMemoryHints {
  CallCardMemoryHints._();

  static String? _outcome(Map<String, dynamic> data) =>
      (data['outcome'] as String?)?.trim().isNotEmpty == true
          ? data['outcome'] as String
          : (data['callOutcome'] as String?)?.trim();

  static String? forFirestore(
    Map<String, dynamic> data, {
    String? notePreview,
  }) {
    final n = notePreview?.trim() ?? '';
    if (n.isNotEmpty) return 'Son not var';

    final oc = _outcome(data) ?? '';
    const reachedLike = {'reached', 'connected', 'completed', 'appointment_set', 'offer_sent'};
    if (reachedLike.contains(oc)) {
      return 'Daha önce ulaşıldı';
    }

    final fu = data['followUpReminderAt'];
    if (fu is Timestamp) {
      if (fu.toDate().isAfter(DateTime.now())) {
        return 'Takipte';
      }
    }

    final created = CrmCallRecordHelpers.createdAtOf(data);
    if (created != null) {
      final d = DateTime.now().difference(created);
      if (d.inHours >= 24 && d.inHours < 48) {
        return 'Son işlem dün';
      }
    }
    return null;
  }

  static String? forLocal({
    required int createdAtMs,
    String? notes,
    String? outcome,
    int? followUpReminderAtMs,
  }) {
    if ((notes ?? '').trim().isNotEmpty) return 'Son not var';
    final fu = followUpReminderAtMs;
    if (fu != null &&
        DateTime.now().millisecondsSinceEpoch < fu) {
      return 'Takipte';
    }
    final oc = (outcome ?? '').trim();
    const reachedLike = {'reached', 'connected', 'completed', 'appointment_set', 'offer_sent'};
    if (reachedLike.contains(oc)) return 'Daha önce ulaşıldı';
    final created = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    final d = DateTime.now().difference(created);
    if (d.inHours >= 24 && d.inHours < 48) return 'Son işlem dün';
    return null;
  }
}
