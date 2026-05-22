import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_extra_page_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/consultant_calls_doc_merge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Son başarılı çağrı listesi — yeniden bağlanırken stale-while-revalidate.
final consultantCallsStaleCacheProvider = NotifierProvider.autoDispose<
    ConsultantCallsStaleCache,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>?>(
  ConsultantCallsStaleCache.new,
);

class ConsultantCallsStaleCache extends AutoDisposeNotifier<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>?> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build() {
    ref.listen(consultantCallsStreamProvider, (_, next) {
      next.whenData((bundle) => state = bundle.docs);
    });
    return null;
  }
}

/// UI için: stream + ek sayfalar; yüklemede/hatada önceki listeyi göster.
final consultantCallsDisplayProvider = Provider.autoDispose<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>(
  (ref) {
    final streamAsync = ref.watch(consultantCallsStreamProvider);
    final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    final extra = uid.isEmpty
        ? const ConsultantCallsExtraPageState()
        : ref.watch(consultantCallsExtraPageProvider(uid));
    final stale = ref.watch(consultantCallsStaleCacheProvider);

    List<QueryDocumentSnapshot<Map<String, dynamic>>> merge(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> base,
    ) =>
        mergeConsultantCallDocs(base, extra.extraDocs);

    return streamAsync.when(
      data: (bundle) => AsyncData(merge(bundle.docs)),
      loading: () => stale != null && stale.isNotEmpty
          ? AsyncData(merge(stale))
          : const AsyncLoading(),
      error: (e, st) => stale != null && stale.isNotEmpty
          ? AsyncData(merge(stale))
          : AsyncError(e, st),
    );
  },
);

/// Stream + ek sayfa birleşik meta (Daha fazla yükle).
final consultantCallsCanLoadMoreProvider = Provider.autoDispose<bool>((ref) {
  final bundle = ref.watch(consultantCallsStreamProvider).valueOrNull;
  final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  if (uid.isEmpty || bundle == null) return false;
  final extra = ref.watch(consultantCallsExtraPageProvider(uid));
  return bundle.hasMore || extra.hasMore;
});
