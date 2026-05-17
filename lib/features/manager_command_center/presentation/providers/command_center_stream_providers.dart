import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Komuta merkezi filtre çubuğu — ekip listesi.
final commandCenterTeamsProvider =
    StreamProvider.autoDispose<List<TeamDoc>>((ref) {
  return FirestoreService.teamsStream();
});

/// Danışman id listesi + görünen adlar (filtre dropdown).
class CommandCenterAgentsFilterData {
  const CommandCenterAgentsFilterData({
    required this.agentIds,
    required this.agentNames,
  });

  final List<String> agentIds;
  final Map<String, String> agentNames;

  static const empty = CommandCenterAgentsFilterData(
    agentIds: [],
    agentNames: {},
  );
}

final commandCenterAgentsFilterProvider =
    StreamProvider.autoDispose<CommandCenterAgentsFilterData>((ref) {
  return FirestoreService.agentsStream().map((snap) {
    if (snap.docs.isEmpty) return CommandCenterAgentsFilterData.empty;
    return CommandCenterAgentsFilterData(
      agentIds: snap.docs.map((d) => d.id).toList(),
      agentNames: {
        for (final d in snap.docs)
          d.id: d.data()['displayName'] as String? ?? d.id,
      },
    );
  });
});

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
