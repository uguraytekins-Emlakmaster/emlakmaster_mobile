import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';

/// Kadro listesi filtreleri — yalnızca gerçek roster sinyalleri.
enum KadroRosterFilter {
  all,
  active,
  intervention,
  silent,
  byTeam,
}

enum KadroConsultantAttention {
  none,
  inactive,
  unassignedTeam,
}

extension KadroConsultantAttentionX on KadroConsultantAttention {
  bool get needsIntervention =>
      this == KadroConsultantAttention.inactive ||
      this == KadroConsultantAttention.unassignedTeam;
}

KadroConsultantAttention kadroAttentionFor(UserDoc user) {
  if (!user.isActive) return KadroConsultantAttention.inactive;
  final tid = user.teamId;
  if (tid == null || tid.isEmpty) {
    return KadroConsultantAttention.unassignedTeam;
  }
  return KadroConsultantAttention.none;
}

bool kadroNeedsIntervention(UserDoc user) =>
    kadroAttentionFor(user).needsIntervention;

List<UserDoc> filterKadroConsultants({
  required List<UserDoc> source,
  required String searchQuery,
  required KadroRosterFilter filter,
  String? teamId,
}) {
  var list = List<UserDoc>.from(source);

  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list.where((u) {
      final name = (u.name ?? '').toLowerCase();
      final email = (u.email ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  switch (filter) {
    case KadroRosterFilter.all:
      break;
    case KadroRosterFilter.active:
      list = list.where((u) => u.isActive).toList();
    case KadroRosterFilter.intervention:
      list = list.where(kadroNeedsIntervention).toList();
    case KadroRosterFilter.silent:
      list = list.where((u) => !u.isActive).toList();
    case KadroRosterFilter.byTeam:
      if (teamId != null && teamId.isNotEmpty) {
        list = list.where((u) => u.teamId == teamId).toList();
      }
  }

  list.sort((a, b) {
    final aInt = kadroNeedsIntervention(a) ? 0 : 1;
    final bInt = kadroNeedsIntervention(b) ? 0 : 1;
    if (aInt != bInt) return aInt.compareTo(bInt);
    final an = (a.name ?? a.email ?? a.uid).toLowerCase();
    final bn = (b.name ?? b.email ?? b.uid).toLowerCase();
    return an.compareTo(bn);
  });

  return list;
}

class KadroTeamSection {
  const KadroTeamSection({
    required this.teamId,
    required this.teamName,
    required this.consultants,
  });

  final String? teamId;
  final String teamName;
  final List<UserDoc> consultants;
}

List<KadroTeamSection> groupKadroByTeam({
  required List<UserDoc> consultants,
  required List<TeamDoc> teams,
}) {
  final byTeam = <String?, List<UserDoc>>{};

  for (final u in consultants) {
    final key = u.teamId;
    byTeam.putIfAbsent(key, () => []).add(u);
  }

  final sections = <KadroTeamSection>[];

  for (final t in teams) {
    final members = byTeam.remove(t.id);
    if (members == null || members.isEmpty) continue;
    sections.add(
      KadroTeamSection(
        teamId: t.id,
        teamName: t.name,
        consultants: members,
      ),
    );
  }

  final unassigned = byTeam.remove(null) ?? [];
  final orphan = byTeam.values.expand((e) => e).toList();
  final loose = [...unassigned, ...orphan];
  if (loose.isNotEmpty) {
    sections.add(
      KadroTeamSection(
        teamId: null,
        teamName: 'Atanmamış',
        consultants: loose,
      ),
    );
  }

  return sections;
}
