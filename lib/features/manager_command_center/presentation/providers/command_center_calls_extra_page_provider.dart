import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/consultant_calls_doc_merge.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_stream_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Komuta merkezi "Daha fazla yükle" — canlı pencere üstündeki eski sayfalar.
class CommandCenterCallsExtraPage {
  const CommandCenterCallsExtraPage({
    this.extraDocs = const [],
    this.loading = false,
    this.hasMore = false,
    this.lastDoc,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> extraDocs;
  final bool loading;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  CommandCenterCallsExtraPage copyWith({
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? extraDocs,
    bool? loading,
    bool? hasMore,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
  }) =>
      CommandCenterCallsExtraPage(
        extraDocs: extraDocs ?? this.extraDocs,
        loading: loading ?? this.loading,
        hasMore: hasMore ?? this.hasMore,
        lastDoc: lastDoc ?? this.lastDoc,
      );
}

class CommandCenterCallsExtraPageNotifier extends AutoDisposeFamilyNotifier<
    CommandCenterCallsExtraPage, CommandCenterCallsScope> {
  @override
  CommandCenterCallsExtraPage build(CommandCenterCallsScope scope) {
    // Canlı pencere değişince (yeni çağrı / audience değişimi) ek sayfaları sıfırla.
    ref.listen(commandCenterCallsStreamProvider(scope), (_, next) {
      if (next.hasValue) state = const CommandCenterCallsExtraPage();
    });
    return const CommandCenterCallsExtraPage();
  }

  Future<void> loadMore() async {
    // Sayfalama yalnızca düz "tümü" akışında anlamlı (pending zaten küçük pencere).
    if (arg != CommandCenterCallsScope.all || state.loading) return;

    final live = ref.read(commandCenterCallsStreamProvider(arg)).valueOrNull;
    if (live == null || live.docs.isEmpty) return;

    final audience = ref.read(commandCenterCallsAudienceProvider);
    if (!audience.hasContext) return;

    final hasMore = state.extraDocs.isEmpty
        ? live.docs.length >= FirestoreService.callsLiveStreamLimit
        : state.hasMore;
    if (!hasMore) return;

    final cursor = state.lastDoc ?? live.docs.last;

    state = state.copyWith(loading: true);
    try {
      final snap = audience.allOffices
          ? await FirestoreService.fetchAllCallsPage(startAfter: cursor)
          : await FirestoreService.fetchCallsByOfficePage(
              audience.officeId,
              startAfter: cursor,
            );
      final merged = mergeConsultantCallDocs(state.extraDocs, snap.docs);
      state = CommandCenterCallsExtraPage(
        extraDocs: merged,
        hasMore: snap.docs.length >= FirestoreService.callsCommandPageSize,
        lastDoc: snap.docs.isNotEmpty ? snap.docs.last : state.lastDoc,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }
}

final commandCenterCallsExtraPageProvider = NotifierProvider.autoDispose.family<
    CommandCenterCallsExtraPageNotifier,
    CommandCenterCallsExtraPage,
    CommandCenterCallsScope>(
  CommandCenterCallsExtraPageNotifier.new,
);

/// "Daha fazla yükle" butonu görünmeli mi?
final commandCenterCallsCanLoadMoreProvider =
    Provider.autoDispose.family<bool, CommandCenterCallsScope>((ref, scope) {
  if (scope != CommandCenterCallsScope.all) return false;
  final live = ref.watch(commandCenterCallsStreamProvider(scope)).valueOrNull;
  if (live == null) return false;
  final extra = ref.watch(commandCenterCallsExtraPageProvider(scope));
  if (extra.loading) return true;
  if (extra.extraDocs.isEmpty) {
    return live.docs.length >= FirestoreService.callsLiveStreamLimit;
  }
  return extra.hasMore;
});
