import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// War Room: Son eklenen lead'ler (Lead Pulse).
final recentLeadsStreamProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirestoreService.recentLeadsStream();
});

/// War Room: Canlı çağrı sayısı.
final liveCallsCountProvider = StreamProvider<int>((ref) {
  return FirestoreService.callsStream().map((s) => s.docs.length);
});

/// War Room: Danışmanlar (Top Performers leaderboard).
final agentsSnapshotProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirestoreService.agentsStream();
});

/// War Room: Aylık satış hedefi.
final officeMonthlyTargetProvider = StreamProvider<int>((ref) {
  return FirestoreService.officeMonthlyTargetStream();
});

/// War Room: Bu ay kapanan deal sayısı (Daily Target Tracker).
final dealsCountProvider = StreamProvider<int>((ref) {
  return FirestoreService.dealsCountStream();
});

/// War Room: Seçili ekip filtresi (null = tüm ekipler).
final warRoomSelectedTeamIdProvider = StateProvider<String?>((ref) => null);

/// War Room: Seçili ekibin üye id listesi (Top Performers filtrelemesi için).
final warRoomTeamMemberIdsProvider = StreamProvider<List<String>>((ref) {
  final teamId = ref.watch(warRoomSelectedTeamIdProvider);
  if (teamId == null || teamId.isEmpty) return Stream.value([]);
  return FirestoreService.teamDocStream(teamId).map((t) => t?.memberIds ?? []);
});
