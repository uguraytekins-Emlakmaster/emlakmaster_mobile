import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';

/// Danışmana ait çağrılar: advisorId ve agentId stream'leri birleştirilip doc.id ile tekilleştirilir.
/// List<QueryDocumentSnapshot> döner; sayfa snapshot.docs yerine bu listeyi kullanır.
final consultantCallsStreamProvider =
    StreamProvider.autoDispose<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) return const Stream.empty();

  final byAdvisor = FirestoreService.callsByAdvisorStream(uid);
  final byAgent = FirestoreService.callsByAgentIdStream(uid);
  final controller = StreamController<List<QueryDocumentSnapshot<Map<String, dynamic>>>>.broadcast();
  QuerySnapshot<Map<String, dynamic>>? lastAdvisor;
  QuerySnapshot<Map<String, dynamic>>? lastAgent;

  void mergeAndEmit() {
    final ids = <String>{};
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final d in lastAdvisor?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      if (ids.add(d.id)) docs.add(d);
    }
    for (final d in lastAgent?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      if (ids.add(d.id)) docs.add(d);
    }
    docs.sort((a, b) {
      final at = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final bt = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return bt.compareTo(at);
    });
    if (!controller.isClosed) controller.add(docs);
  }

  final sub1 = byAdvisor.listen((s) {
    lastAdvisor = s;
    mergeAndEmit();
  }, onError: controller.addError, onDone: () {});
  final sub2 = byAgent.listen((s) {
    lastAgent = s;
    mergeAndEmit();
  }, onError: controller.addError, onDone: () {});

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});
