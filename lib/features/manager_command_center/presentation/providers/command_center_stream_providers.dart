import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Komuta merkezi çağrı akışı kapsamı.
enum CommandCenterCallsScope {
  all,
  pending,
}

final commandCenterAgentNamesProvider =
    StreamProvider.autoDispose<Map<String, String>>((ref) {
  return FirestoreService.agentsStream().map((snap) {
    return {
      for (final d in snap.docs)
        d.id: d.data()['displayName'] as String? ?? d.id,
    };
  });
});

final commandCenterCallsStreamProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, CommandCenterCallsScope>(
        (ref, scope) {
  switch (scope) {
    case CommandCenterCallsScope.pending:
      return FirestoreService.callsHandoffPendingStream();
    case CommandCenterCallsScope.all:
      return FirestoreService.callsStream();
  }
});
