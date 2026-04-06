import 'dart:async';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/pending_handoff_outbound_item.dart';
import 'package:emlakmaster_mobile/features/calls/data/pending_handoff_outbound_queue.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yerel `local_…` taslak için ~8 sn sonra otomatik minimum `calls` satırı (veri kaybı önleme).
const Duration _kFallbackDelay = Duration(seconds: 8);

final postCallCaptureProvider =
    StateNotifierProvider<PostCallCaptureNotifier, PostCallCaptureDraft?>((ref) {
  final notifier = PostCallCaptureNotifier(ref);
  ref.onDispose(() {
    notifier.disposeFallbackTimer();
    notifier.disposeOnlineSubscription();
  });
  return notifier;
});

class PostCallCaptureNotifier extends StateNotifier<PostCallCaptureDraft?> {
  PostCallCaptureNotifier(this.ref) : super(null) {
    unawaited(_sync());
    ref.listen(currentUserProvider, (prev, next) {
      unawaited(_sync());
    });
    _onlineSub = SyncManager.onlineStream.listen((online) {
      if (online) {
        unawaited(flushPendingOutboundQueue());
      }
    });
  }

  final Ref ref;
  Timer? _fallbackTimer;
  StreamSubscription<bool>? _onlineSub;

  /// Ardışık flush — yarışta çift upsert azaltır.
  Future<void> _flushTail = Future<void>.value();

  void disposeFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  void disposeOnlineSubscription() {
    _onlineSub?.cancel();
    _onlineSub = null;
  }

  /// Yerel kuyruktaki çağrıları Firestore'a yazar; çevrimiçi olunca sessiz tekrar.
  Future<void> flushPendingOutboundQueue() {
    _flushTail = _flushTail
        .then((_) => _flushPendingOutboundQueueImpl())
        .catchError((Object e, StackTrace st) {
      AppLogger.w('flushPendingOutboundQueue chain', e, st);
    });
    return _flushTail;
  }

  Future<void> _flushPendingOutboundQueueImpl() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    final items = await PendingHandoffOutboundQueue.load(uid);
    if (items.isEmpty) return;

    for (final item in List<PendingHandoffOutboundItem>.from(items)) {
      try {
        final stillPending = await PendingHandoffOutboundQueue.containsLocalDraftId(
          uid,
          item.localDraftId,
        );
        if (!stillPending) continue;

        final docId = FirestoreService.stableFallbackCallDocumentId(
          item.localDraftId,
          item.advisorId,
        );
        await FirestoreService.upsertMinimalFallbackCallRecord(
          documentId: docId,
          advisorId: item.advisorId,
          customerId: item.customerId,
          phoneNumber: item.phoneNumber,
          startedFromScreen: item.startedFromScreen,
          flushedFromOfflineQueue: true,
        );
        await PendingHandoffOutboundQueue.removeByLocalDraftId(uid, item.localDraftId);
        final current = state;
        if (current != null && current.callSessionId == item.localDraftId) {
          await upgradeLocalDraftToDocId(docId);
        }
      } catch (e, st) {
        AppLogger.w('flushPendingOutboundQueue item', e, st);
      }
    }
  }

  /// `local_…` taslak kimliğini Firestore `hf_…` doc id ile değiştirir (merge yolu açılır).
  Future<void> upgradeLocalDraftToDocId(String firestoreDocId) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    final current = state;
    if (uid.isEmpty || current == null) return;
    if (!current.callSessionId.startsWith(PostCallCaptureDraft.localPrefix)) return;
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
    state = await PostCallCaptureStore.load(uid);
    unawaited(flushPendingOutboundQueue());
    _scheduleFallbackIfNeeded(state);
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
      final docId = await FirestoreService.createMinimalFallbackCallRecord(
        advisorId: uid,
        localDraftId: current.callSessionId,
        customerId: current.customerId,
        phoneNumber: current.phone,
        startedFromScreen: current.startedFromScreen,
      );
      await PendingHandoffOutboundQueue.removeByLocalDraftId(uid, current.callSessionId);
      final next = current.copyWith(callSessionId: docId);
      await PostCallCaptureStore.save(uid, next);
      state = next;
    } catch (e, st) {
      AppLogger.e('createMinimalFallbackCallRecord', e, st);
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

  Future<void> beginHandoff(PostCallCaptureDraft draft) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    await PostCallCaptureStore.save(uid, draft);
    state = draft;
    _scheduleFallbackIfNeeded(draft);
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
    if (d != null && d.callSessionId.startsWith(PostCallCaptureDraft.localPrefix)) {
      await PendingHandoffOutboundQueue.removeByLocalDraftId(uid, d.callSessionId);
    }
    await PostCallCaptureStore.clear(uid);
    state = null;
  }
}
