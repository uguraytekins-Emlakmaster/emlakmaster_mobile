import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/consultant_calls_doc_merge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConsultantCallsExtraPageState {
  const ConsultantCallsExtraPageState({
    this.extraDocs = const [],
    this.loading = false,
    this.hasMoreAdvisor = false,
    this.hasMoreAgent = false,
    this.lastAdvisorDoc,
    this.lastAgentDoc,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> extraDocs;
  final bool loading;
  final bool hasMoreAdvisor;
  final bool hasMoreAgent;
  final DocumentSnapshot<Map<String, dynamic>>? lastAdvisorDoc;
  final DocumentSnapshot<Map<String, dynamic>>? lastAgentDoc;

  bool get hasMore => hasMoreAdvisor || hasMoreAgent;
}

class ConsultantCallsExtraPageNotifier
    extends AutoDisposeFamilyNotifier<ConsultantCallsExtraPageState, String> {
  @override
  ConsultantCallsExtraPageState build(String uid) {
    ref.listen(consultantCallsStreamProvider, (previous, next) {
      if (next.hasValue) {
        state = const ConsultantCallsExtraPageState();
      }
    });
    return const ConsultantCallsExtraPageState();
  }

  Future<void> loadMore(String uid) async {
    if (uid.isEmpty || state.loading) return;
    final bundle = ref.read(consultantCallsStreamProvider).valueOrNull;
    if (bundle == null) return;

    final hasMoreAdvisor =
        state.extraDocs.isEmpty ? bundle.hasMoreAdvisor : state.hasMoreAdvisor;
    final hasMoreAgent =
        state.extraDocs.isEmpty ? bundle.hasMoreAgent : state.hasMoreAgent;
    if (!hasMoreAdvisor && !hasMoreAgent) return;

    final advisorCursor = state.lastAdvisorDoc ?? bundle.lastAdvisorDoc;
    final agentCursor = state.lastAgentDoc ?? bundle.lastAgentDoc;
    final loadAdvisor = hasMoreAdvisor && advisorCursor != null;
    final loadAgent = hasMoreAgent && agentCursor != null;
    if (!loadAdvisor && !loadAgent) return;

    state = ConsultantCallsExtraPageState(
      extraDocs: state.extraDocs,
      loading: true,
      hasMoreAdvisor: state.hasMoreAdvisor,
      hasMoreAgent: state.hasMoreAgent,
      lastAdvisorDoc: state.lastAdvisorDoc,
      lastAgentDoc: state.lastAgentDoc,
    );

    try {
      final batch = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      var hasMoreAdvisor = false;
      var hasMoreAgent = false;
      DocumentSnapshot<Map<String, dynamic>>? lastAdvisor;
      DocumentSnapshot<Map<String, dynamic>>? lastAgent;

      if (loadAdvisor) {
        final snap = await FirestoreService.fetchCallsByAdvisorPage(
          uid,
          startAfter: advisorCursor,
        );
        batch.addAll(snap.docs);
        hasMoreAdvisor = snap.docs.length >= FirestoreService.callsListPageSize;
        if (snap.docs.isNotEmpty) lastAdvisor = snap.docs.last;
      }

      if (loadAgent) {
        final snap = await FirestoreService.fetchCallsByAgentIdPage(
          uid,
          startAfter: agentCursor,
        );
        batch.addAll(snap.docs);
        hasMoreAgent = snap.docs.length >= FirestoreService.callsListPageSize;
        if (snap.docs.isNotEmpty) lastAgent = snap.docs.last;
      }

      final merged = mergeConsultantCallDocs(state.extraDocs, batch);
      state = ConsultantCallsExtraPageState(
        extraDocs: merged,
        hasMoreAdvisor: hasMoreAdvisor,
        hasMoreAgent: hasMoreAgent,
        lastAdvisorDoc: lastAdvisor ?? state.lastAdvisorDoc,
        lastAgentDoc: lastAgent ?? state.lastAgentDoc,
      );
    } finally {
      state = ConsultantCallsExtraPageState(
        extraDocs: state.extraDocs,
        loading: false,
        hasMoreAdvisor: state.hasMoreAdvisor,
        hasMoreAgent: state.hasMoreAgent,
        lastAdvisorDoc: state.lastAdvisorDoc,
        lastAgentDoc: state.lastAgentDoc,
      );
    }
  }
}

final consultantCallsExtraPageProvider = NotifierProvider.autoDispose.family<
    ConsultantCallsExtraPageNotifier,
    ConsultantCallsExtraPageState,
    String>(
  ConsultantCallsExtraPageNotifier.new,
);
