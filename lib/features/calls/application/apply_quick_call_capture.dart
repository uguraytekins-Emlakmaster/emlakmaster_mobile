import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hızlı çağrı kaydını Firestore’a uygular ve bekleyen taslağı temizler.
Future<void> applyQuickCallCapture({
  required WidgetRef ref,
  required PostCallCaptureDraft draft,
  required String outcomeCode,
  String? note,
  DateTime? followUpReminderAt,
  bool createFollowUpTask = false,
  /// `hot` | `warm` | `cold` — opsiyonel sıcaklık ipucu
  String? heatBand,
}) async {
  final uid = ref.read(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) return;

  final label = QuickCallOutcome.labelTr(outcomeCode);
  final trimmed = note?.trim();

  final signals = _signalsFor(outcomeCode, heatBand);

  await runWithResilience(
    () async {
      if (draft.hasFirestoreCallDoc) {
        await FirestoreService.mergeOutboundCallQuickCapture(
          callSessionId: draft.callSessionId,
          quickOutcomeCode: outcomeCode,
          quickOutcomeLabelTr: label,
          quickNote: trimmed,
          followUpReminderAt: followUpReminderAt,
        );
      } else {
        await FirestoreService.createCallRecordWithQuickCapture(
          advisorId: uid,
          customerId: draft.customerId,
          phoneNumber: draft.phone,
          startedFromScreen: draft.startedFromScreen,
          quickOutcomeCode: outcomeCode,
          quickOutcomeLabelTr: label,
          quickNote: trimmed,
          followUpReminderAt: followUpReminderAt,
        );
      }

      final cid = draft.customerId;
      if (cid != null && cid.isNotEmpty) {
        final noteLine = StringBuffer('📞 Hızlı kayıt: $label');
        if (trimmed != null && trimmed.isNotEmpty) {
          noteLine.write(' — $trimmed');
        }
        noteLine.write(' (cihaz telefonu, süre uygulamada ölçülmedi)');
        await FirestoreService.mergeCustomerAfterQuickCallCapture(
          customerId: cid,
          advisorId: uid,
          noteLine: noteLine.toString(),
          lastCallSummarySignalsPayload: signals,
        );
      }

      if (createFollowUpTask && cid != null && cid.isNotEmpty) {
        final due = followUpReminderAt ??
            DateTime.now().add(const Duration(days: 1));
        await FirestoreService.setTask({
          'advisorId': uid,
          'customerId': cid,
          'title': 'Takip: $label',
          'dueAt': Timestamp.fromDate(due),
          'done': false,
        });
      }
    },
    ref: ref as Ref<Object?>,
  );

  await ref.read(postCallCaptureProvider.notifier).clear();
}

Map<String, dynamic>? _signalsFor(String outcomeCode, String? heatBand) {
  final interest = switch (heatBand) {
    'hot' => PostCallCrmSignals.interestHigh,
    'warm' => PostCallCrmSignals.interestMedium,
    'cold' => PostCallCrmSignals.interestLow,
    _ => PostCallCrmSignals.interestMedium,
  };
  final urgency = outcomeCode == QuickCallOutcome.callbackScheduled
      ? PostCallCrmSignals.urgencyHigh
      : outcomeCode == QuickCallOutcome.noAnswer ||
              outcomeCode == QuickCallOutcome.busy
          ? PostCallCrmSignals.urgencyMedium
          : PostCallCrmSignals.urgencyLow;

  return PostCallCrmSignals(
    interestLevel: interest,
    nextActionHint: QuickCallOutcome.labelTr(outcomeCode),
    appointmentMentioned: outcomeCode == QuickCallOutcome.appointmentSet,
    priceObjection: false,
    followUpUrgency: urgency,
  ).toFirestorePayload();
}
