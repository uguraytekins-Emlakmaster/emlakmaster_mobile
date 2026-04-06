import 'dart:async';

import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final postCallCaptureProvider =
    StateNotifierProvider<PostCallCaptureNotifier, PostCallCaptureDraft?>((ref) {
  return PostCallCaptureNotifier(ref);
});

class PostCallCaptureNotifier extends StateNotifier<PostCallCaptureDraft?> {
  PostCallCaptureNotifier(this.ref) : super(null) {
    unawaited(_sync());
    ref.listen(currentUserProvider, (prev, next) {
      unawaited(_sync());
    });
  }

  final Ref ref;

  Future<void> _sync() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      state = null;
      return;
    }
    state = await PostCallCaptureStore.load(uid);
  }

  Future<void> beginHandoff(PostCallCaptureDraft draft) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    await PostCallCaptureStore.save(uid, draft);
    state = draft;
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
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    await PostCallCaptureStore.clear(uid);
    state = null;
  }
}
