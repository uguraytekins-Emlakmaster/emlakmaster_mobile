import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/consultant_calls_doc_merge.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_calls_extra_page_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_stream_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Son başarılı Komuta Merkezi çağrı listesi — yeniden bağlanırken SWR.
final commandCenterCallsStaleCacheProvider = NotifierProvider.autoDispose
    .family<CommandCenterCallsStaleCache,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>?,
        CommandCenterCallsScope>(CommandCenterCallsStaleCache.new);

class CommandCenterCallsStaleCache extends AutoDisposeFamilyNotifier<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>?,
    CommandCenterCallsScope> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(
    CommandCenterCallsScope scope,
  ) {
    ref.listen(commandCenterCallsStreamProvider(scope), (_, next) {
      next.whenData((snap) => state = snap.docs);
    });
    return null;
  }
}

/// UI: yüklemede/hatada önceki çağrı listesini göster.
final commandCenterCallsDisplayProvider = Provider.autoDispose.family<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>,
    CommandCenterCallsScope>((ref, scope) {
  final streamAsync = ref.watch(commandCenterCallsStreamProvider(scope));
  final stale = ref.watch(commandCenterCallsStaleCacheProvider(scope));
  final extra = ref.watch(commandCenterCallsExtraPageProvider(scope));

  List<QueryDocumentSnapshot<Map<String, dynamic>>> merge(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> base,
  ) =>
      mergeConsultantCallDocs(base, extra.extraDocs);

  return streamAsync.when(
    data: (snap) => AsyncData(merge(snap.docs)),
    loading: () => stale != null && stale.isNotEmpty
        ? AsyncData(merge(stale))
        : const AsyncLoading(),
    error: (e, st) => stale != null && stale.isNotEmpty
        ? AsyncData(merge(stale))
        : AsyncError(e, st),
  );
});
