import 'dart:async';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yerel `local_…` taslak için ~8 sn sonra otomatik minimum `calls` satırı (veri kaybı önleme).
const Duration _kFallbackDelay = Duration(seconds: 8);

final postCallCaptureProvider =
    StateNotifierProvider<PostCallCaptureNotifier, PostCallCaptureDraft?>((ref) {
  final notifier = PostCallCaptureNotifier(ref);
  ref.onDispose(notifier.disposeFallbackTimer);
  return notifier;
});

class PostCallCaptureNotifier extends StateNotifier<PostCallCaptureDraft?> {
  PostCallCaptureNotifier(this.ref) : super(null) {
    unawaited(_sync());
    ref.listen(currentUserProvider, (prev, next) {
      unawaited(_sync());
    });
  }

  final Ref ref;
  Timer? _fallbackTimer;

  void disposeFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  Future<void> _sync() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      state = null;
      return;
    }
    state = await PostCallCaptureStore.load(uid);
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
        customerId: current.customerId,
        phoneNumber: current.phone,
        startedFromScreen: current.startedFromScreen,
      );
      final next = current.copyWith(callSessionId: docId);
      await PostCallCaptureStore.save(uid, next);
      state = next;
    } catch (e, st) {
      AppLogger.e('createMinimalFallbackCallRecord', e, st);
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
    await PostCallCaptureStore.clear(uid);
    state = null;
  }
}
