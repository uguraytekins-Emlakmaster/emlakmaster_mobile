import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/call_local_hive_store.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/features/calls/domain/callback_queue_item.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/callback_queue_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickCaptureSaveResult {
  const QuickCaptureSaveResult({
    required this.savedSuccessfully,
    required this.callSaved,
    required this.taskCreated,
    required this.customerLinked,
    required this.detachedCallSummarySaved,
    this.customerId,
    this.firestoreCallId,
    /// Çağrı satırı Firestore’da tamam; müşteri notu veya görev aşaması başarısızsa Türkçe kısa uyarı.
    this.enrichmentWarningTr,
  });

  final bool savedSuccessfully;
  final bool callSaved;
  final bool taskCreated;
  final bool customerLinked;
  final bool detachedCallSummarySaved;
  final String? customerId;
  final String? firestoreCallId;
  final String? enrichmentWarningTr;
}

String? _nonLocalFirestoreCallId(String? id) {
  const lp = PostCallCaptureDraft.localPrefix;
  if (id == null || id.isEmpty || id.startsWith(lp)) return null;
  return id;
}

/// Hive’daki gerçek `calls/{id}` ile taslak `callSessionId` (hâlâ `local_…`) çakışmasını çözer.
String? resolveQuickCaptureFirestoreCallId({
  required PostCallCaptureDraft draft,
  required LocalCallRecord? hiveRow,
}) {
  final draftId = _nonLocalFirestoreCallId(draft.callSessionId);
  final hiveId = _nonLocalFirestoreCallId(hiveRow?.firestoreDocumentId);

  if (draft.crmSessionTracked && draftId != null) {
    return draftId;
  }
  if (hiveId != null) {
    return hiveId;
  }
  if (draftId != null) {
    return draftId;
  }
  return null;
}

void _logQuickCaptureFirestoreError(
  String phase, {
  required Object error,
  StackTrace? stackTrace,
  String? method,
  String? documentPath,
}) {
  final b = StringBuffer('[quick_capture][$phase]');
  if (method != null) b.write(' method=$method');
  if (documentPath != null) b.write(' path=$documentPath');
  b.write(' type=${error.runtimeType}');
  if (error is FirebaseException) {
    b.write(' code=${error.code} message=${error.message}');
  } else {
    b.write(' message=$error');
  }
  final line = b.toString();
  AppLogger.e(line, error, stackTrace);
  if (kDebugMode) {
    AppLogger.d(line);
  }
}

/// Hızlı çağrı kaydını Firestore’a uygular ve bekleyen taslağı temizler.
Future<QuickCaptureSaveResult> applyQuickCallCapture({
  required WidgetRef ref,
  BuildContext? context,
  required PostCallCaptureDraft draft,
  required String outcomeCode,
  String? note,
  DateTime? followUpReminderAt,
  bool createFollowUpTask = false,

  /// `hot` | `warm` | `cold` — opsiyonel sıcaklık ipucu
  String? heatBand,
}) async {
  final uid = ref.read(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    AppLogger.forensic(
      'quick_capture: ABORT no uid',
    );
    throw StateError('Oturum bulunamadı. Tekrar giriş yapıp deneyin.');
  }
  final customerLinked =
      draft.customerId != null && draft.customerId!.isNotEmpty;
  AppLogger.forensic(
    'quick_capture: button/engine start local=${draft.localRecordId} '
    'session=${draft.callSessionId} linked=$customerLinked '
    'createTask=$createFollowUpTask outcome=$outcomeCode',
  );
  if (kDebugMode) {
    AppLogger.d(
      '[quick_capture] save start local=${draft.localRecordId} '
      'session=${draft.callSessionId} createTask=$createFollowUpTask '
      'customer=${draft.customerId ?? '-'}',
    );
  }

  // Yerel taslak: önce kuyruk flush zincirini bekle (arka planda hf_ oluşmuş olabilir).
  if (draft.localRecordId.startsWith(PostCallCaptureDraft.localPrefix)) {
    AppLogger.forensic('quick_capture: flushPendingOutboundQueue start');
    try {
      await ref
          .read(postCallCaptureProvider.notifier)
          .flushPendingOutboundQueue()
          .timeout(const Duration(seconds: 6));
    } on TimeoutException catch (_) {
      AppLogger.forensic(
        'quick_capture: flushPendingOutboundQueue TIMEOUT 6s — continuing save',
      );
    }
    AppLogger.forensic('quick_capture: flushPendingOutboundQueue end');
  }

  var effective = draft;
  final live = ref.read(postCallCaptureProvider);
  if (live != null &&
      live.phone == draft.phone &&
      live.createdAtMs == draft.createdAtMs) {
    effective = live;
    if (kDebugMode) {
      AppLogger.d(
          '[quick_capture] live draft override used ${live.localRecordId}');
    }
  }

  final label = QuickCallOutcome.labelTr(outcomeCode);
  final trimmed = note?.trim();

  await CallLocalHiveStore.instance.ensureInit();
  AppLogger.forensic('quick_capture: hive patchQuickCapture start');
  await CallLocalHiveStore.instance.patchQuickCapture(
    agentId: uid,
    localId: effective.localRecordId,
    outcomeCode: outcomeCode,
    notes: trimmed,
    followUpReminderAtMs: followUpReminderAt?.millisecondsSinceEpoch,
  );
  AppLogger.forensic('quick_capture: hive patchQuickCapture done');

  final cid = effective.customerId;

  final signals = _signalsFor(
    outcomeCode: outcomeCode,
    heatBand: heatBand,
    note: trimmed,
  );

  var taskCreated = false;
  final hiveAfterPatch =
      await CallLocalHiveStore.instance.get(uid, effective.localRecordId);
  final resolvedCallId = resolveQuickCaptureFirestoreCallId(
    draft: effective,
    hiveRow: hiveAfterPatch,
  );
  final branch = resolvedCallId != null ? 'merge' : 'create';
  AppLogger.forensic(
    'quick_capture: Firestore resolve branch=$branch '
    'draftSession=${effective.callSessionId} '
    'hiveFid=${hiveAfterPatch?.firestoreDocumentId ?? '-'} '
    'resolved=${resolvedCallId ?? '-'} crmTracked=${effective.crmSessionTracked}',
  );

  final String canonicalCallId;
  try {
    canonicalCallId = await runWithResilienceWidget<String>(
      () async {
        if (resolvedCallId != null) {
          await FirestoreService.mergeOutboundCallQuickCapture(
            callSessionId: resolvedCallId,
            quickOutcomeCode: outcomeCode,
            quickOutcomeLabelTr: label,
            quickNote: trimmed,
            followUpReminderAt: followUpReminderAt,
          );
          return resolvedCallId;
        }
        return FirestoreService.createCallRecordWithQuickCapture(
          advisorId: uid,
          customerId: effective.customerId,
          phoneNumber: effective.phone,
          startedFromScreen: effective.startedFromScreen,
          quickOutcomeCode: outcomeCode,
          quickOutcomeLabelTr: label,
          quickNote: trimmed,
          followUpReminderAt: followUpReminderAt,
        );
      },
      ref: ref,
    );
  } catch (e, st) {
    final path = resolvedCallId != null
        ? '${AppConstants.colCalls}/$resolvedCallId'
        : '${AppConstants.colCalls}<(create)>';
    _logQuickCaptureFirestoreError(
      'call_doc',
      error: e,
      stackTrace: st,
      method: resolvedCallId != null
          ? 'mergeOutboundCallQuickCapture'
          : 'createCallRecordWithQuickCapture',
      documentPath: path,
    );
    AppLogger.forensic(
      'quick_capture: Firestore call_doc FINAL error ${e.runtimeType}',
    );
    rethrow;
  }

  final curHive =
      await CallLocalHiveStore.instance.get(uid, effective.localRecordId);
  if (curHive != null &&
      (curHive.firestoreDocumentId == null ||
          curHive.firestoreDocumentId != canonicalCallId)) {
    await CallLocalHiveStore.instance.replaceFirestoreDocumentId(
      agentId: uid,
      localId: effective.localRecordId,
      firestoreDocumentId: canonicalCallId,
    );
  }

  final warnings = <String>[];
  if (cid != null && cid.isNotEmpty) {
    try {
      await runWithResilienceWidget(
        () async {
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
        },
        ref: ref,
      );
    } catch (e, st) {
      _logQuickCaptureFirestoreError(
        'customer_enrich',
        error: e,
        stackTrace: st,
        method: 'mergeCustomerAfterQuickCallCapture',
        documentPath: '${AppConstants.colCustomers}/$cid',
      );
      warnings.add(
        'Çağrı kaydı tamam; müşteri kartına not veya sinyal yazılamadı: '
        '${FirestoreService.userFacingErrorMessage(e)}',
      );
    }
  }

  if (createFollowUpTask) {
    AppLogger.forensic('quick_capture: task create start');
    try {
      await runWithResilienceWidget(
        () async {
          final due =
              followUpReminderAt ?? DateTime.now().add(const Duration(days: 1));
          await FirestoreService.setTask({
            'advisorId': uid,
            'title': 'Takip: $label',
            'dueAt': Timestamp.fromDate(due),
            'done': false,
            if (cid != null && cid.isNotEmpty) 'customerId': cid,
            'phoneNumber': effective.phone,
            'source': 'post_call_quick_capture',
          });
        },
        ref: ref,
      );
      taskCreated = true;
      AppLogger.forensic('quick_capture: task create done');
    } catch (e, st) {
      _logQuickCaptureFirestoreError(
        'task',
        error: e,
        stackTrace: st,
        method: 'setTask',
        documentPath: AppConstants.colTasks,
      );
      warnings.add(
        'Takip görevi oluşturulamadı: '
        '${FirestoreService.userFacingErrorMessage(e)}',
      );
    }
  }

  AppLogger.forensic(
    'quick_capture: Firestore phases done canonicalId=$canonicalCallId '
    'task=$taskCreated warnings=${warnings.length}',
  );

  await CallLocalHiveStore.instance.markSynced(
    agentId: uid,
    localId: effective.localRecordId,
    clearPendingCapture: true,
  );
  if (outcomeCode == QuickCallOutcome.callbackScheduled) {
    final due =
        followUpReminderAt ?? DateTime.now().add(const Duration(minutes: 15));
    final now = DateTime.now();
    await ref.read(callbackQueueProvider.notifier).enqueue(
          CallbackQueueItem(
            id: '${now.millisecondsSinceEpoch}_${effective.phone.hashCode}',
            phone: effective.phone,
            customerId: cid,
            note: trimmed ?? '',
            dueAtMs: due.millisecondsSinceEpoch,
            createdAtMs: now.millisecondsSinceEpoch,
          ),
        );
  }

  await ref.read(postCallCaptureProvider.notifier).clear();
  AppLogger.forensic('quick_capture: provider invalidate start');
  ref.invalidate(localCallRecordsStreamProvider);
  ref.invalidate(consultantCallsStreamProvider);
  ref.invalidate(customerListForAgentProvider);
  ref.invalidate(advisorTasksMetaProvider);
  if (cid != null && cid.isNotEmpty) {
    ref.invalidate(customerInsightProvider(cid));
  }
  AppLogger.forensic('quick_capture: provider invalidate done');
  if (kDebugMode) {
    AppLogger.i(
      '[quick_capture] save success local=${effective.localRecordId} '
      'firestore=$canonicalCallId '
      'taskCreated=$taskCreated',
    );
  }
  AppLogger.forensic(
    'quick_capture: RETURN success linked=${cid != null && cid.isNotEmpty}',
  );
  return QuickCaptureSaveResult(
    savedSuccessfully: true,
    callSaved: true,
    taskCreated: taskCreated,
    customerLinked: cid != null && cid.isNotEmpty,
    detachedCallSummarySaved: false,
    customerId: cid,
    firestoreCallId: canonicalCallId,
    enrichmentWarningTr: warnings.isEmpty ? null : warnings.join('\n'),
  );
}

Map<String, dynamic>? _signalsFor({
  required String outcomeCode,
  String? heatBand,
  String? note,
}) {
  final outcomeLabel = QuickCallOutcome.labelTr(outcomeCode);
  final seed = [
    if (note != null && note.isNotEmpty) note,
    outcomeLabel,
  ].join(' ');
  var signals = extractPostCallCrmSignals(seed);

  if (heatBand != null && heatBand.isNotEmpty) {
    final interest = switch (heatBand) {
      'hot' => PostCallCrmSignals.interestHigh,
      'warm' => PostCallCrmSignals.interestMedium,
      'cold' => PostCallCrmSignals.interestLow,
      _ => signals.interestLevel,
    };
    signals = PostCallCrmSignals(
      interestLevel: interest,
      nextActionHint: signals.nextActionHint,
      appointmentMentioned: signals.appointmentMentioned,
      priceObjection: signals.priceObjection,
      followUpUrgency: signals.followUpUrgency,
    );
  }

  if (outcomeCode == QuickCallOutcome.callbackScheduled &&
      signals.followUpUrgency == PostCallCrmSignals.urgencyNone) {
    signals = PostCallCrmSignals(
      interestLevel: signals.interestLevel,
      nextActionHint: signals.nextActionHint.isNotEmpty
          ? signals.nextActionHint
          : 'Planlanan geri aramayı takvime ve göreve bağlayın.',
      appointmentMentioned: signals.appointmentMentioned,
      priceObjection: signals.priceObjection,
      followUpUrgency: PostCallCrmSignals.urgencyHigh,
    );
  }
  if (outcomeCode == QuickCallOutcome.appointmentSet) {
    signals = PostCallCrmSignals(
      interestLevel: signals.interestLevel,
      nextActionHint: signals.nextActionHint,
      appointmentMentioned: true,
      priceObjection: signals.priceObjection,
      followUpUrgency: signals.followUpUrgency,
    );
  }
  if (signals.nextActionHint.isEmpty) {
    signals = PostCallCrmSignals(
      interestLevel: signals.interestLevel,
      nextActionHint: outcomeLabel,
      appointmentMentioned: signals.appointmentMentioned,
      priceObjection: signals.priceObjection,
      followUpUrgency: signals.followUpUrgency,
    );
  }

  return signals.toFirestorePayload();
}
