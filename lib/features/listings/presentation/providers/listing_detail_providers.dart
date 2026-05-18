import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final listingDocStreamProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, String>((ref, listingId) {
  return FirestoreService.listingDocStream(listingId);
});

final listingDocStaleCacheProvider = NotifierProvider.autoDispose
    .family<ListingDocStaleCache, DocumentSnapshot<Map<String, dynamic>>?, String>(
  ListingDocStaleCache.new,
);

class ListingDocStaleCache extends AutoDisposeFamilyNotifier<
    DocumentSnapshot<Map<String, dynamic>>?, String> {
  @override
  DocumentSnapshot<Map<String, dynamic>>? build(String listingId) {
    ref.listen(listingDocStreamProvider(listingId), (_, next) {
      next.whenData((snap) => state = snap);
    });
    return null;
  }
}

final listingDocDisplayProvider = Provider.autoDispose
    .family<AsyncValue<DocumentSnapshot<Map<String, dynamic>>>, String>(
  (ref, listingId) {
    final streamAsync = ref.watch(listingDocStreamProvider(listingId));
    final stale = ref.watch(listingDocStaleCacheProvider(listingId));
    return streamAsync.when(
      data: (snap) => AsyncData(snap),
      loading: () => stale != null
          ? AsyncData(stale)
          : const AsyncLoading(),
      error: (e, st) => stale != null && stale.exists
          ? AsyncData(stale)
          : AsyncError(e, st),
    );
  },
);
