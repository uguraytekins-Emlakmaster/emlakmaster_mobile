import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yönetici KPI şeridi — ofis geneli ajan özetleri.
class BrokerAgentsKpiSnapshot {
  const BrokerAgentsKpiSnapshot({
    required this.missedCalls,
    required this.activeAdvisors,
    required this.activeCalls,
  });

  final int missedCalls;
  final int activeAdvisors;
  final int activeCalls;

  static const empty = BrokerAgentsKpiSnapshot(
    missedCalls: 0,
    activeAdvisors: 0,
    activeCalls: 0,
  );
}

final brokerOpenTasksCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirestoreService.openTasksCountStream();
});

final brokerAgentsKpiSnapshotProvider =
    StreamProvider.autoDispose<BrokerAgentsKpiSnapshot>((ref) {
  return FirestoreService.agentsStream().map((snap) {
    if (snap.docs.isEmpty) return BrokerAgentsKpiSnapshot.empty;
    var missed = 0;
    var advisors = 0;
    var activeCalls = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      missed += (data['missedCalls'] as num?)?.toInt() ?? 0;
      advisors++;
      if ((data['status'] as String?) == 'Görüşmede') activeCalls++;
    }
    return BrokerAgentsKpiSnapshot(
      missedCalls: missed,
      activeAdvisors: advisors,
      activeCalls: activeCalls,
    );
  });
});

/// Danışman haftalık arama sayacı.
final agentWeeklyCallCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, uid) {
  if (uid.isEmpty) return Stream<int>.value(0);
  return FirestoreService.agentWeeklyCallCountStream(uid);
});

/// Ekip belgesi (dashboard hero).
final teamDocSnapshotProvider =
    StreamProvider.autoDispose.family<TeamDoc?, String>((ref, teamId) {
  if (teamId.isEmpty) return Stream<TeamDoc?>.value(null);
  return FirestoreService.teamDocStream(teamId);
});
