import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
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
      next.whenData((data) => state = data);
    });
    return null;
  }
}

/// UI için: yüklemede/hatada önceki listeyi göster.
final consultantCallsDisplayProvider = Provider.autoDispose<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>(
  (ref) {
    final streamAsync = ref.watch(consultantCallsStreamProvider);
    final stale = ref.watch(consultantCallsStaleCacheProvider);
    return streamAsync.when(
      data: (data) => AsyncData(data),
      loading: () => stale != null && stale.isNotEmpty
          ? AsyncData(stale)
          : const AsyncLoading(),
      error: (e, st) => stale != null && stale.isNotEmpty
          ? AsyncData(stale)
          : AsyncError(e, st),
    );
  },
);
