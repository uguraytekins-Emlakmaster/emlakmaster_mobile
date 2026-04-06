import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/call_local_hive_store.dart';
import 'package:emlakmaster_mobile/features/calls/data/pending_handoff_outbound_queue.dart';
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

  // Yerel taslak: önce kuyruk flush zincirini bekle (arka planda hf_ oluşmuş olabilir).
  if (draft.localRecordId.startsWith(PostCallCaptureDraft.localPrefix)) {
    await ref.read(postCallCaptureProvider.notifier).flushPendingOutboundQueue();
  }

  var effective = draft;
  final live = ref.read(postCallCaptureProvider);
  if (live != null &&
      live.phone == draft.phone &&
      live.createdAtMs == draft.createdAtMs) {
    effective = live;
  }

  final label = QuickCallOutcome.labelTr(outcomeCode);
  final trimmed = note?.trim();

  await CallLocalHiveStore.instance.ensureInit();
  await CallLocalHiveStore.instance.patchQuickCapture(
    agentId: uid,
    localId: effective.localRecordId,
    outcomeCode: outcomeCode,
    notes: trimmed,
    followUpReminderAtMs: followUpReminderAt?.millisecondsSinceEpoch,
  );

  if (effective.localRecordId.startsWith(PostCallCaptureDraft.localPrefix)) {
    await PendingHandoffOutboundQueue.removeByLocalDraftId(
      uid,
      effective.localRecordId,
    );
  }

  final signals = _signalsFor(outcomeCode, heatBand);

  String? newFirestoreCallId;
  await runWithResilience(
    () async {
      if (effective.hasFirestoreCallDoc) {
        await FirestoreService.mergeOutboundCallQuickCapture(
          callSessionId: effective.callSessionId,
          quickOutcomeCode: outcomeCode,
          quickOutcomeLabelTr: label,
          quickNote: trimmed,
          followUpReminderAt: followUpReminderAt,
        );
      } else {
        newFirestoreCallId = await FirestoreService.createCallRecordWithQuickCapture(
          advisorId: uid,
          customerId: effective.customerId,
          phoneNumber: effective.phone,
          startedFromScreen: effective.startedFromScreen,
          quickOutcomeCode: outcomeCode,
          quickOutcomeLabelTr: label,
          quickNote: trimmed,
          followUpReminderAt: followUpReminderAt,
        );
      }

      final cid = effective.customerId;
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

  if (newFirestoreCallId != null && newFirestoreCallId!.isNotEmpty) {
    await CallLocalHiveStore.instance.replaceFirestoreDocumentId(
      agentId: uid,
      localId: effective.localRecordId,
      firestoreDocumentId: newFirestoreCallId!,
    );
  }

  await CallLocalHiveStore.instance.markSynced(
    agentId: uid,
    localId: effective.localRecordId,
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
