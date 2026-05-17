import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final todayCallsCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirestoreService.todayCallsCountStream();
});

final advisorOpenTasksCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, uid) {
  if (uid.isEmpty) return Stream<int>.value(0);
  return FirestoreService.tasksByAdvisorStream(uid)
      .map((snap) => snap.docs.length);
});

final advisorPipelineCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, uid) {
  if (uid.isEmpty) return Stream<int>.value(0);
  return FirestoreService.pipelineItemsByAdvisorStream(uid)
      .map((snap) => snap.docs.length);
});
