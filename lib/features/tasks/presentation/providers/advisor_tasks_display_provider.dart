import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_stream_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final advisorTasksStaleCacheProvider = NotifierProvider.autoDispose
    .family<AdvisorTasksStaleCache,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String>(
  AdvisorTasksStaleCache.new,
);

class AdvisorTasksStaleCache extends AutoDisposeFamilyNotifier<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(String uid) {
    ref.listen(advisorTasksStreamProvider(uid), (_, next) {
      next.whenData((snap) => state = snap.docs);
    });
    return null;
  }
}

final advisorTasksDisplayProvider = Provider.autoDispose.family<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>, String>(
  (ref, uid) {
    final streamAsync = ref.watch(advisorTasksStreamProvider(uid));
    final stale = ref.watch(advisorTasksStaleCacheProvider(uid));
    return streamAsync.when(
      data: (snap) => AsyncData(snap.docs),
      loading: () => stale != null && stale.isNotEmpty
          ? AsyncData(stale)
          : const AsyncLoading(),
      error: (e, st) => stale != null && stale.isNotEmpty
          ? AsyncData(stale)
          : AsyncError(e, st),
    );
  },
);
