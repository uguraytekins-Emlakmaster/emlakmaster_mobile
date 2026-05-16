import 'dart:async';

import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/callback_queue_store.dart';
import 'package:emlakmaster_mobile/features/calls/domain/callback_queue_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final callbackQueueProvider =
    StateNotifierProvider<CallbackQueueNotifier, List<CallbackQueueItem>>((ref) {
  return CallbackQueueNotifier(ref);
});

class CallbackQueueNotifier extends StateNotifier<List<CallbackQueueItem>> {
  CallbackQueueNotifier(this.ref) : super(const []) {
    unawaited(_sync());
    ref.listen(currentUserProvider, (prev, next) {
      if (prev?.valueOrNull?.uid == next.valueOrNull?.uid) return;
      unawaited(_sync());
    });
  }

  final Ref ref;

  Future<void> _sync() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      state = const [];
      return;
    }
    final items = await CallbackQueueStore.load(uid);
    final now = DateTime.now().millisecondsSinceEpoch;
    final active = items
        .where((e) => !e.completed && e.dueAtMs > now - const Duration(days: 7).inMilliseconds)
        .toList()
      ..sort((a, b) => a.dueAtMs.compareTo(b.dueAtMs));
    state = active;
    if (active.length != items.length) {
      await CallbackQueueStore.save(uid, active);
    }
  }

  Future<void> enqueue(CallbackQueueItem item) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    final next = [item, ...state.where((e) => e.id != item.id)]
      ..sort((a, b) => a.dueAtMs.compareTo(b.dueAtMs));
    await CallbackQueueStore.save(uid, next.take(CallbackQueueStore.maxItems).toList());
    state = next.take(CallbackQueueStore.maxItems).toList();
  }

  Future<void> complete(String id) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    final next = state.map((e) => e.id == id ? e.copyWith(completed: true) : e).toList();
    await CallbackQueueStore.save(
      uid,
      next.where((e) => !e.completed).toList(),
    );
    state = next.where((e) => !e.completed).toList();
  }
}
