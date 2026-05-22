import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/models/consultant_calls_stream_bundle.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';

/// Danışmana ait çağrılar: advisorId ve agentId stream'leri birleştirilir.
final consultantCallsStreamProvider = StreamProvider.autoDispose<
    ConsultantCallsStreamBundle>((ref) {
  final uid = ref.watch(
    currentUserProvider.select((v) => v.valueOrNull?.uid),
  );
  if (uid == null || uid.isEmpty) return const Stream.empty();

  final byAdvisor = FirestoreService.callsByAdvisorStream(uid);
  final byAgent = FirestoreService.callsByAgentIdStream(uid);
  final controller = StreamController<ConsultantCallsStreamBundle>.broadcast();
  QuerySnapshot<Map<String, dynamic>>? lastAdvisor;
  QuerySnapshot<Map<String, dynamic>>? lastAgent;
  int? lastFingerprint;
  var hasEmittedInitial = false;

  int fingerprint(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    var h = docs.length;
    for (final d in docs) {
      final data = d.data();
      h = Object.hash(
        h,
        d.id,
        data['createdAt'],
        data['updatedAt'],
        data['outcome'],
        data['quickOutcomeCode'],
      );
    }
    return h;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> mergeDocs() {
    final ids = <String>{};
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final d in lastAdvisor?.docs ??
        <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      if (ids.add(d.id)) docs.add(d);
    }
    for (final d
        in lastAgent?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      if (ids.add(d.id)) docs.add(d);
    }
    docs.sort((a, b) {
      final at =
          (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final bt =
          (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return bt.compareTo(at);
    });
    return docs;
  }

  void mergeAndEmit() {
    final docs = mergeDocs();
    final nextFingerprint = fingerprint(docs);
    if (nextFingerprint == lastFingerprint && hasEmittedInitial) return;
    lastFingerprint = nextFingerprint;
    hasEmittedInitial = true;
    if (controller.isClosed) return;

    final advisorLen = lastAdvisor?.docs.length ?? 0;
    final agentLen = lastAgent?.docs.length ?? 0;
    final bundle = ConsultantCallsStreamBundle(
      docs: docs,
      hasMoreAdvisor: advisorLen >= FirestoreService.callsListPageSize,
      hasMoreAgent: agentLen >= FirestoreService.callsListPageSize,
      lastAdvisorDoc: advisorLen > 0 ? lastAdvisor!.docs.last : null,
      lastAgentDoc: agentLen > 0 ? lastAgent!.docs.last : null,
    );
    controller.add(bundle);
    AppLogger.d(
      '[consultantCallsStreamProvider] emit docs=${docs.length} '
      'advisor=$advisorLen agent=$agentLen',
    );
  }

  void onAdvisorError(Object e, StackTrace st) {
    debugPrint('[consultantCallsStreamProvider] advisor: $e');
    lastAdvisor = null;
    mergeAndEmit();
  }

  void onAgentError(Object e, StackTrace st) {
    debugPrint('[consultantCallsStreamProvider] agent: $e');
    lastAgent = null;
    mergeAndEmit();
  }

  final sub1 = byAdvisor.listen((s) {
    lastAdvisor = s;
    mergeAndEmit();
  }, onError: onAdvisorError, onDone: () {});
  final sub2 = byAgent.listen((s) {
    lastAgent = s;
    mergeAndEmit();
  }, onError: onAgentError, onDone: () {});

  scheduleMicrotask(() {
    if (!controller.isClosed && !hasEmittedInitial) {
      hasEmittedInitial = true;
      lastFingerprint = fingerprint(const []);
      controller.add(ConsultantCallsStreamBundle.empty);
      AppLogger.d('[consultantCallsStreamProvider] initial empty emit');
    }
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});
