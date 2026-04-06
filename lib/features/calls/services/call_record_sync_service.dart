import 'dart:async';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/observability/crashlytics_reporting.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:emlakmaster_mobile/features/calls/data/call_local_hive_store.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Yerel çağrı kayıtlarını Firestore ile sessizce hizalar (UI bloklamaz).
class CallRecordSyncService {
  CallRecordSyncService._();

  static Future<void> _chain = Future<void>.value();

  /// Tek sıra — yarışta çift yazım azaltılır.
  static Future<void> syncForCurrentUser() {
    _chain = _chain.then((_) => _syncForCurrentUserImpl()).catchError((Object e, StackTrace st) {
      AppLogger.w('CallRecordSyncService chain', e, st);
      CrashlyticsReporting.recordNonFatal(e, st, reason: 'CallRecordSyncService chain');
    });
    return _chain;
  }

  static Future<void> _syncForCurrentUserImpl() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    if (!SyncManager.instance.isOnline) return;

    await CallLocalHiveStore.instance.ensureInit();
    await CallLocalHiveStore.instance.migrateLegacyPendingQueue(uid);

    final pending = await CallLocalHiveStore.instance.listReadyToSync(uid);
    if (pending.isEmpty) return;

    for (final r in pending) {
      try {
        await _syncOneRecord(r);
      } catch (e, st) {
        AppLogger.w('CallRecordSyncService record ${r.id}', e, st);
        CrashlyticsReporting.recordNonFatal(e, st, reason: 'CallRecordSyncService record');
        await CallLocalHiveStore.instance.recordSyncFailure(
          agentId: uid,
          localId: r.id,
        );
      }
    }
  }

  static Future<void> _syncOneRecord(LocalCallRecord r) async {
    final uid = r.agentId;
    if (uid.isEmpty) return;

    await CallLocalHiveStore.instance.setSyncing(agentId: uid, localId: r.id, syncing: true);
    try {
      await CallLocalHiveStore.instance.applyPendingCapturePatchIfAny(
        agentId: uid,
        localId: r.id,
      );
      var fresh = await CallLocalHiveStore.instance.get(uid, r.id);
      if (fresh == null) return;
      if (fresh.syncFailedPermanent) return;

      late final String firestoreId;
      if (fresh.firestoreDocumentId == null) {
        final deduped = await FirestoreService.findExistingCallInDedupeWindow(
          advisorId: uid,
          phoneNumber: fresh.phoneNumber,
          createdAtMs: fresh.createdAt,
        );
        if (deduped != null) {
          firestoreId = deduped;
          await CallLocalHiveStore.instance.replaceFirestoreDocumentId(
            agentId: uid,
            localId: fresh.id,
            firestoreDocumentId: firestoreId,
          );
        } else {
          firestoreId = FirestoreService.stableFallbackCallDocumentId(fresh.id, uid);
          await FirestoreService.upsertMinimalFallbackCallRecord(
            documentId: firestoreId,
            advisorId: uid,
            customerId: fresh.customerId,
            phoneNumber: fresh.phoneNumber,
            startedFromScreen: fresh.startedFromScreen,
            flushedFromOfflineQueue: true,
          );
          await CallLocalHiveStore.instance.replaceFirestoreDocumentId(
            agentId: uid,
            localId: fresh.id,
            firestoreDocumentId: firestoreId,
          );
        }
      } else {
        firestoreId = fresh.firestoreDocumentId!;
      }

      fresh = await CallLocalHiveStore.instance.get(uid, r.id);
      if (fresh == null) return;

      if (fresh.hasQuickCapturePayload) {
        final label = QuickCallOutcome.labelTr(fresh.outcome!.trim());
        await FirestoreService.mergeOutboundCallQuickCapture(
          callSessionId: firestoreId,
          quickOutcomeCode: fresh.outcome!.trim(),
          quickOutcomeLabelTr: label,
          quickNote: fresh.notes,
          followUpReminderAt: fresh.followUpReminderAtMs != null
              ? DateTime.fromMillisecondsSinceEpoch(fresh.followUpReminderAtMs!)
              : null,
        );
        await CallLocalHiveStore.instance.markSynced(agentId: uid, localId: fresh.id);
        await _maybeApplyQueuedAndResync(uid, fresh.id);
        return;
      }

      if (!fresh.hasQuickCapturePayload) {
        if (firestoreId.startsWith('hf_')) {
          await FirestoreService.upsertMinimalFallbackCallRecord(
            documentId: firestoreId,
            advisorId: uid,
            customerId: fresh.customerId,
            phoneNumber: fresh.phoneNumber,
            startedFromScreen: fresh.startedFromScreen,
            flushedFromOfflineQueue: true,
          );
        }
        await CallLocalHiveStore.instance.markSynced(agentId: uid, localId: fresh.id);
        await _maybeApplyQueuedAndResync(uid, fresh.id);
      }
    } finally {
      await CallLocalHiveStore.instance.setSyncing(agentId: uid, localId: r.id, syncing: false);
    }
  }

  static Future<void> _maybeApplyQueuedAndResync(String uid, String localId) async {
    await CallLocalHiveStore.instance.applyPendingCapturePatchIfAny(
      agentId: uid,
      localId: localId,
    );
    final after = await CallLocalHiveStore.instance.get(uid, localId);
    if (after != null &&
        after.hasQuickCapturePayload &&
        !after.isSynced) {
      unawaited(syncForCurrentUser());
    }
  }

  /// Mevcut taslak ile aynı yerel kimlikte Hive satırını günceller (başka akışlardan).
  static Future<void> ensureDraftMirroredInHive({
    required String agentId,
    required PostCallCaptureDraft draft,
  }) async {
    if (!draft.localRecordId.startsWith(PostCallCaptureDraft.localPrefix)) return;
    await CallLocalHiveStore.instance.insertCallStart(
      agentId: agentId,
      localId: draft.localRecordId,
      phoneNumber: draft.phone,
      createdAtMs: draft.createdAtMs,
      customerId: draft.customerId,
      startedFromScreen: draft.startedFromScreen,
    );
    if (!draft.callSessionId.startsWith(PostCallCaptureDraft.localPrefix)) {
      await CallLocalHiveStore.instance.replaceFirestoreDocumentId(
        agentId: agentId,
        localId: draft.localRecordId,
        firestoreDocumentId: draft.callSessionId,
      );
    }
  }
}
