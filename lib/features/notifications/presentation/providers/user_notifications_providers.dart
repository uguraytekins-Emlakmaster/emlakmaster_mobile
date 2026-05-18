import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userNotificationsStreamProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String>((ref, uid) {
  return FirestoreService.notificationsByUserStream(uid);
});

final userNotificationsStaleCacheProvider = NotifierProvider.autoDispose
    .family<UserNotificationsStaleCache,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String>(
  UserNotificationsStaleCache.new,
);

class UserNotificationsStaleCache extends AutoDisposeFamilyNotifier<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(String uid) {
    ref.listen(userNotificationsStreamProvider(uid), (_, next) {
      next.whenData((snap) => state = snap.docs);
    });
    return null;
  }
}

final userNotificationsDisplayProvider = Provider.autoDispose.family<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>, String>(
  (ref, uid) {
    final streamAsync = ref.watch(userNotificationsStreamProvider(uid));
    final stale = ref.watch(userNotificationsStaleCacheProvider(uid));
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
