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

    late final String firestoreId;
    if (r.firestoreDocumentId == null) {
      firestoreId = FirestoreService.stableFallbackCallDocumentId(r.id, uid);
      await FirestoreService.upsertMinimalFallbackCallRecord(
        documentId: firestoreId,
        advisorId: uid,
        customerId: r.customerId,
        phoneNumber: r.phoneNumber,
        startedFromScreen: r.startedFromScreen,
        flushedFromOfflineQueue: true,
      );
      await CallLocalHiveStore.instance.replaceFirestoreDocumentId(
        agentId: uid,
        localId: r.id,
        firestoreDocumentId: firestoreId,
      );
    } else {
      firestoreId = r.firestoreDocumentId!;
    }

    if (r.hasQuickCapturePayload) {
      final label = QuickCallOutcome.labelTr(r.outcome!.trim());
      await FirestoreService.mergeOutboundCallQuickCapture(
        callSessionId: firestoreId,
        quickOutcomeCode: r.outcome!.trim(),
        quickOutcomeLabelTr: label,
        quickNote: r.notes,
        followUpReminderAt: r.followUpReminderAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(r.followUpReminderAtMs!)
            : null,
      );
      await CallLocalHiveStore.instance.markSynced(agentId: uid, localId: r.id);
      return;
    }

    if (!r.hasQuickCapturePayload) {
      if (firestoreId.startsWith('hf_')) {
        await FirestoreService.upsertMinimalFallbackCallRecord(
          documentId: firestoreId,
          advisorId: uid,
          customerId: r.customerId,
          phoneNumber: r.phoneNumber,
          startedFromScreen: r.startedFromScreen,
          flushedFromOfflineQueue: true,
        );
      }
      await CallLocalHiveStore.instance.markSynced(agentId: uid, localId: r.id);
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
