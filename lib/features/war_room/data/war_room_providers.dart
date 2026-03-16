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
