import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman görevleri — tek Firestore aboneliği (sayfa + sheet paylaşır).
final advisorTasksStreamProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String>((ref, uid) {
  return FirestoreService.tasksByAdvisorStream(uid);
});
