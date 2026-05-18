import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ofis müşteri araması (komut paleti vb.) — tek abonelik.
final officeCustomersSnapshotProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirestoreService.customersStream();
});

final customerCallsStreamProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String>((ref, customerId) {
  return FirestoreService.callsByCustomerStream(customerId);
});

final customerCallsStaleCacheProvider = NotifierProvider.autoDispose
    .family<CustomerCallsStaleCache,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String>(
  CustomerCallsStaleCache.new,
);

class CustomerCallsStaleCache extends AutoDisposeFamilyNotifier<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(String customerId) {
    ref.listen(customerCallsStreamProvider(customerId), (_, next) {
      next.whenData((snap) => state = snap.docs);
    });
    return null;
  }
}

final customerCallsDisplayProvider = Provider.autoDispose.family<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>, String>(
  (ref, customerId) {
    final streamAsync = ref.watch(customerCallsStreamProvider(customerId));
    final stale = ref.watch(customerCallsStaleCacheProvider(customerId));
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

final customerNotesStreamProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String>((ref, customerId) {
  return FirestoreService.notesByCustomerStream(customerId);
});

final customerNotesStaleCacheProvider = NotifierProvider.autoDispose
    .family<CustomerNotesStaleCache,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String>(
  CustomerNotesStaleCache.new,
);

class CustomerNotesStaleCache extends AutoDisposeFamilyNotifier<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>?, String> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(String customerId) {
    ref.listen(customerNotesStreamProvider(customerId), (_, next) {
      next.whenData((snap) => state = snap.docs);
    });
    return null;
  }
}

final customerNotesDisplayProvider = Provider.autoDispose.family<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>, String>(
  (ref, customerId) {
    final streamAsync = ref.watch(customerNotesStreamProvider(customerId));
    final stale = ref.watch(customerNotesStaleCacheProvider(customerId));
    return streamAsync.when(
      data: (snap) => AsyncData(snap.docs),
      loading: () => stale != null
          ? AsyncData(stale)
          : const AsyncLoading(),
      error: (e, st) => stale != null
          ? AsyncData(stale)
          : AsyncError(e, st),
    );
  },
);
