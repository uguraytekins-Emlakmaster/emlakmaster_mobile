import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_repository.dart';
import 'package:emlakmaster_mobile/features/messages/data/user_profile_cache.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_entity.dart';
import 'package:emlakmaster_mobile/features/office/data/office_membership_repository.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Giriş yapan kullanıcının birincil ofis kimliği.
final teamChatOfficeIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return null;
  final doc = ref.watch(userDocStreamProvider(user.uid)).valueOrNull;
  final oid = doc?.officeId;
  if (oid == null || oid.isEmpty) return null;
  return oid;
});

void _keepTeamChatAlive(Ref ref, String? officeId) {
  if (officeId == null) return;
  final link = ref.keepAlive();
  ref.onDispose(link.close);
}

final teamChannelsProvider = StreamProvider<List<TeamChannel>>((ref) {
  final officeId = ref.watch(teamChatOfficeIdProvider);
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (officeId == null || uid == null) {
    return Stream<List<TeamChannel>>.value(const []);
  }
  _keepTeamChatAlive(ref, officeId);
  return TeamChatRepository.watchChannelsForUser(officeId, uid);
});

class TeamThreadArgs {
  const TeamThreadArgs({required this.officeId, required this.channelId});

  final String officeId;
  final String channelId;

  @override
  bool operator ==(Object other) {
    return other is TeamThreadArgs &&
        other.officeId == officeId &&
        other.channelId == channelId;
  }

  @override
  int get hashCode => Object.hash(officeId, channelId);
}

class TeamMemberProfile {
  const TeamMemberProfile({
    required this.membership,
    this.user,
  });

  final OfficeMembership membership;
  final UserDoc? user;

  String get displayName {
    final n = user?.name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = user?.email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return 'Ekip üyesi';
  }

  String? get avatarUrl => user?.avatarUrl;
}

/// Aktif ofis üyeleri + profil (üyelik stream + paralel önbellekli profil okuma).
final officeTeamMemberProfilesProvider =
    StreamProvider<List<TeamMemberProfile>>((ref) {
  final officeId = ref.watch(teamChatOfficeIdProvider);
  final currentUid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (officeId == null) return Stream.value(const []);

  _keepTeamChatAlive(ref, officeId);

  return OfficeMembershipRepository.watchMembershipsForOffice(officeId)
      .asyncMap((memberships) async {
    final active = memberships
        .where((m) => m.status == MembershipStatus.active)
        .where((m) => m.userId != currentUid)
        .toList();
    if (active.isEmpty) return const <TeamMemberProfile>[];

    final userMap =
        await UserProfileCache.instance.getMany(active.map((m) => m.userId));

    final profiles = active
        .map(
          (m) => TeamMemberProfile(
            membership: m,
            user: userMap[m.userId],
          ),
        )
        .toList()
      ..sort(
        (a, b) => a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase()),
      );
    return List.unmodifiable(profiles);
  });
});

/// Tek seferlik genel kanal hazırlığı (ofis başına).
final teamGeneralChannelReadyProvider = FutureProvider<void>((ref) async {
  final officeId = ref.watch(teamChatOfficeIdProvider);
  if (officeId == null) return;
  _keepTeamChatAlive(ref, officeId);
  await TeamChatRepository.ensureGeneralChannel(officeId);
});
