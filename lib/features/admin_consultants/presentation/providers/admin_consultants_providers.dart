import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman yönetimi — tek ekip aboneliği.
final adminConsultantsTeamsProvider =
    StreamProvider.autoDispose<List<TeamDoc>>((ref) {
  return FirestoreService.teamsStream();
});

/// Danışman yönetimi — tek danışman listesi aboneliği.
final adminConsultantsListProvider =
    StreamProvider.autoDispose<List<UserDoc>>((ref) {
  return FirestoreService.consultantsStream();
});
