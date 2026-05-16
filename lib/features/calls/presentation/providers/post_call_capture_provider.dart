import 'dart:async';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/observability/crashlytics_reporting.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/call_local_hive_store.dart';
import 'package:emlakmaster_mobile/features/calls/data/pending_handoff_outbound_item.dart';
import 'package:emlakmaster_mobile/features/calls/data/pending_handoff_outbound_queue.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_store.dart';
import 'package:emlakmaster_mobile/features/calls/domain/call_session_reliability.dart';
import 'package:emlakmaster_mobile/features/calls/services/call_record_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yerel `local_…` taslak için ~8 sn sonra otomatik senkron denemesi (veri kaybı önleme).
const Duration _kFallbackDelay = Duration(seconds: 8);

final postCallCaptureProvider =
    StateNotifierProvider<PostCallCaptureNotifier, PostCallCaptureDraft?>((ref) {
  final notifier = PostCallCaptureNotifier(ref);
  ref.onDispose(() {
    notifier.disposeFallbackTimer();
    notifier.disposeConnectivitySubscriptions();
    notifier.disposeUserResyncDebounce();
  });
  return notifier;
});

class PostCallCaptureNotifier extends StateNotifier<PostCallCaptureDraft?> {
  PostCallCaptureNotifier(this.ref) : super(null) {
    unawaited(_sync());
    ref.listen(currentUserProvider, (prev, next) {
      final prevUid = prev?.valueOrNull?.uid;
      final nextUid = next.valueOrNull?.uid;
      if (prevUid == nextUid) return;
      _userResyncDebounce?.cancel();
      _userResyncDebounce = Timer(const Duration(milliseconds: 450), () {
        _userResyncDebounce = null;
        unawaited(_sync());
      });
    });
    _onlineSub = SyncManager.onlineStreamDebounced.listen((online) {
      if (online) {
        unawaited(flushPendingOutboundQueue());
      }
    });
    _resumeSub = AppLifecyclePowerService.onAppResumed.listen((_) {
      unawaited(flushPendingOutboundQueue());
    });
  }

  final Ref ref;
  Timer? _fallbackTimer;
  Timer? _userResyncDebounce;
  StreamSubscription<bool>? _onlineSub;
  StreamSubscription<void>? _resumeSub;

  /// Ardışık flush — yarışta çift yazım azaltır.
  Future<void> _flushTail = Future<void>.value();

  void disposeFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  void disposeConnectivitySubscriptions() {
    _onlineSub?.cancel();
    _onlineSub = null;
    _resumeSub?.cancel();
    _resumeSub = null;
  }

  void disposeUserResyncDebounce() {
    _userResyncDebounce?.cancel();
    _userResyncDebounce = null;
  }

  /// Hive + Firestore senkronu; UI bloklamaz.
  Future<void> flushPendingOutboundQueue() {
    _flushTail = _flushTail
        .then((_) => _flushPendingOutboundQueueImpl())
        .catchError((Object e, StackTrace st) {
      AppLogger.w('flushPendingOutboundQueue chain', e, st);
      CrashlyticsReporting.recordNonFatal(
        e,
        st,
        reason: 'flushPendingOutboundQueue chain',
      );
    });
    return _flushTail;
  }

  Future<void> _flushPendingOutboundQueueImpl() async {
    await CallRecordSyncService.syncForCurrentUser();
    await _refreshDraftFromHiveIfNeeded();
  }

  Future<void> _refreshDraftFromHiveIfNeeded() async {
    final current = state;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (current == null || uid.isEmpty) return;
    if (!current.callSessionId.startsWith(PostCallCaptureDraft.localPrefix)) return;
    final row = await CallLocalHiveStore.instance.get(uid, current.localRecordId);
    final fid = row?.firestoreDocumentId;
    if (fid == null || fid.isEmpty) return;
    if (!fid.startsWith(PostCallCaptureDraft.localPrefix) &&
        fid != current.callSessionId) {
      await upgradeLocalDraftToDocId(fid);
    }
  }

  /// `local_…` taslak kimliğini Firestore `calls/{id}` ile değiştirir (merge yolu açılır).
  Future<void> upgradeLocalDraftToDocId(String firestoreDocId) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    final current = state;
    if (uid.isEmpty || current == null) return;
    if (!current.callSessionId.startsWith(PostCallCaptureDraft.localPrefix)) return;
    await CallLocalHiveStore.instance.replaceFirestoreDocumentId(
      agentId: uid,
      localId: current.localRecordId,
      firestoreDocumentId: firestoreDocId,
    );
    final next = current.copyWith(callSessionId: firestoreDocId);
    await PostCallCaptureStore.save(uid, next);
    state = next;
  }

  Future<void> _sync() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      state = null;
      return;
    }
    var loaded = await PostCallCaptureStore.load(uid);
    if (loaded != null && CallSessionReliability.isDraftStale(loaded.createdAtMs)) {
      await PostCallCaptureStore.clear(uid);
      loaded = null;
    }
    state = loaded;
    unawaited(flushPendingOutboundQueue());
    _scheduleFallbackIfNeeded(state);
  }

  bool get shouldOfferReturnPrompt {
    final d = state;
    if (d == null) return false;
    return CallSessionReliability.shouldOfferReturnPrompt(
      createdAtMs: d.createdAtMs,
      startedFromScreen: d.startedFromScreen,
      returnPromptShown: d.returnPromptShown,
      captureCompleted: false,
    );
  }

  bool get shouldShowRecoveryCard {
    final d = state;
    if (d == null) return false;
    if (d.recoveryDismissed || !d.captureAbandoned) return false;
    if (CallSessionReliability.isDraftStale(d.createdAtMs)) return false;
    return true;
  }

  Future<void> markReturnPromptShown() async {
    final d = state;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (d == null || uid.isEmpty) return;
    final next = d.copyWith(returnPromptShown: true);
    await PostCallCaptureStore.save(uid, next);
    state = next;
  }

  Future<void> markCaptureInProgress() async {
    final d = state;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (d == null || uid.isEmpty) return;
    if (!d.captureAbandoned) return;
    final next = d.copyWith(captureAbandoned: false);
    await PostCallCaptureStore.save(uid, next);
    state = next;
  }

  Future<void> markCaptureAbandoned() async {
    final d = state;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (d == null || uid.isEmpty) return;
    final next = d.copyWith(captureAbandoned: true);
    await PostCallCaptureStore.save(uid, next);
    state = next;
  }

  Future<void> dismissRecovery() async {
    final d = state;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (d == null || uid.isEmpty) return;
    final next = d.copyWith(recoveryDismissed: true);
    await PostCallCaptureStore.save(uid, next);
    state = next;
  }

  void _scheduleFallbackIfNeeded(PostCallCaptureDraft? d) {
    disposeFallbackTimer();
    if (d == null) return;
    if (!d.callSessionId.startsWith(PostCallCaptureDraft.localPrefix)) return;

    final elapsed = DateTime.now().millisecondsSinceEpoch - d.createdAtMs;
    final remainingMs = _kFallbackDelay.inMilliseconds - elapsed;
    final delay =
        remainingMs <= 0 ? Duration.zero : Duration(milliseconds: remainingMs);

    final expectedId = d.callSessionId;
    _fallbackTimer = Timer(delay, () {
      unawaited(_writeFallbackIfStillLocal(expectedId));
    });
  }

  Future<void> _writeFallbackIfStillLocal(String expectedLocalId) async {
    final current = state;
    if (current == null) return;
    if (current.callSessionId != expectedLocalId) return;
    if (!current.callSessionId.startsWith(PostCallCaptureDraft.localPrefix)) {
      return;
    }

    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      await CallRecordSyncService.syncForCurrentUser();
      await _refreshDraftFromHiveIfNeeded();
    } catch (e, st) {
      AppLogger.e('call fallback sync', e, st);
      CrashlyticsReporting.recordNonFatal(
        e,
        st,
        reason: 'call fallback sync',
      );
      await PendingHandoffOutboundQueue.upsert(
        PendingHandoffOutboundItem(
          localDraftId: current.callSessionId,
          advisorId: uid,
          customerId: current.customerId,
          phoneNumber: current.phone,
          startedFromScreen: current.startedFromScreen,
          createdAtMs: current.createdAtMs,
        ),
      );
    }
  }

  /// Güvenilir post-call tetikleyici: uygulama içi GSM handoff + taslak.
  /// Saf yerel Phone araması için garanti verilmez (iOS kısıtı).
  Future<void> beginHandoff(PostCallCaptureDraft draft) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    await CallRecordSyncService.ensureDraftMirroredInHive(
      agentId: uid,
      draft: draft,
    );
    await PostCallCaptureStore.save(uid, draft);
    state = draft;
    _scheduleFallbackIfNeeded(draft);
    unawaited(CallRecordSyncService.syncForCurrentUser());
  }

  Future<void> dismissStrip() async {
    final d = state;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (d == null || uid.isEmpty) return;
    final next = d.copyWith(dismissedFromStrip: true);
    await PostCallCaptureStore.save(uid, next);
    state = next;
  }

  Future<void> clear() async {
    disposeFallbackTimer();
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    final d = state;
    if (d != null && d.localRecordId.startsWith(PostCallCaptureDraft.localPrefix)) {
      await PendingHandoffOutboundQueue.removeByLocalDraftId(uid, d.localRecordId);
    }
    await PostCallCaptureStore.clear(uid);
    state = null;
  }
}
