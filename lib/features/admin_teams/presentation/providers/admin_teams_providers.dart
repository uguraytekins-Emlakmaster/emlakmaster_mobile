import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ekip listesi — [adminConsultantsTeamsProvider] ile aynı stream (tek abonelik).
final adminTeamsListProvider = adminConsultantsTeamsProvider;

/// Ekip detay belgesi.
final adminTeamDocProvider = StreamProvider.autoDispose.family<TeamDoc?, String>(
  (ref, teamId) => FirestoreService.teamDocStream(teamId),
);

/// Yönetici / danışman listesi — detay sayfası dropdown.
final adminTeamManagersProvider = adminConsultantsListProvider;
