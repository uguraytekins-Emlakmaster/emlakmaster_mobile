import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pipelineItemsStreamProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String>((ref, uid) {
  return FirestoreService.pipelineItemsByAdvisorStream(uid);
});

final pipelineItemsStaleCacheProvider = NotifierProvider.autoDispose
    .family<PipelineItemsStaleCache,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String>(
  PipelineItemsStaleCache.new,
);

class PipelineItemsStaleCache extends AutoDisposeFamilyNotifier<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(String uid) {
    ref.listen(pipelineItemsStreamProvider(uid), (_, next) {
      next.whenData((snap) => state = snap.docs);
    });
    return null;
  }
}

final pipelineItemsDisplayProvider = Provider.autoDispose.family<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>, String>(
  (ref, uid) {
    final streamAsync = ref.watch(pipelineItemsStreamProvider(uid));
    final stale = ref.watch(pipelineItemsStaleCacheProvider(uid));
    return streamAsync.when(
      data: (snap) => AsyncData(snap.docs),
      loading: () => stale != null
          ? AsyncData(stale)
          : const AsyncLoading(),
      error: (e, st) => stale != null && stale.isNotEmpty
          ? AsyncData(stale)
          : AsyncError(e, st),
    );
  },
);
