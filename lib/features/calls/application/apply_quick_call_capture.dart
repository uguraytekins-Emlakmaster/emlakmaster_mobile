import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/call_local_hive_store.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/upgrade_bottom_sheet.dart';
import 'package:emlakmaster_mobile/features/monetization/services/usage_service.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickCaptureSaveResult {
  const QuickCaptureSaveResult({
    required this.savedSuccessfully,
    required this.callSaved,
    required this.taskCreated,
    required this.customerLinked,
    required this.detachedCallSummarySaved,
    required this.aiLimited,
    this.customerId,
    this.firestoreCallId,
  });

  final bool savedSuccessfully;
  final bool callSaved;
  final bool taskCreated;
  final bool customerLinked;
  final bool detachedCallSummarySaved;
  final bool aiLimited;
  final String? customerId;
  final String? firestoreCallId;
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
  var canUseAi = true;
  if (cid != null && cid.isNotEmpty) {
    final usageService = ref.read(usageServiceProvider);
    await usageService.warmUp();
    canUseAi = usageService.canUseAi();
    if (canUseAi) {
      await usageService.incrementAiUsage();
    } else {
      AnalyticsService.instance.logEvent(
        AnalyticsEvents.limitReachedAi,
        {AnalyticsEvents.paramFeature: 'ai_analysis'},
      );
      if (context != null && context.mounted) {
        await showUpgradeBottomSheet(
          context,
          feature: 'ai_analysis',
        );
      }
      if (kDebugMode) {
        AppLogger.i(
            '[quick_capture] ai limit reached, save continues without AI');
      }
    }
  }

  final signals = canUseAi ? _signalsFor(outcomeCode, heatBand) : null;

  String? newFirestoreCallId;
  var taskCreated = false;
  AppLogger.forensic(
    'quick_capture: Firestore runWithResilience start hasDoc=${effective.hasFirestoreCallDoc}',
  );
  try {
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
          newFirestoreCallId =
              await FirestoreService.createCallRecordWithQuickCapture(
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

        if (createFollowUpTask) {
          AppLogger.forensic('quick_capture: task create start');
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
          taskCreated = true;
          AppLogger.forensic('quick_capture: task create done');
        }
      },
      ref: ref as Ref<Object?>,
    );
  } catch (e, st) {
    AppLogger.forensic(
        'quick_capture: Firestore path FINAL error ${e.runtimeType}');
    AppLogger.e('quick_capture: Firestore path failed', e, st);
    rethrow;
  }
  AppLogger.forensic(
    'quick_capture: Firestore runWithResilience done newId=${newFirestoreCallId ?? '-'} task=$taskCreated',
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
    clearPendingCapture: true,
  );
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
      'firestore=${newFirestoreCallId ?? effective.callSessionId} '
      'taskCreated=$taskCreated aiLimited=${!canUseAi}',
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
    aiLimited: !canUseAi,
    customerId: cid,
    firestoreCallId: newFirestoreCallId ?? effective.callSessionId,
  );
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
