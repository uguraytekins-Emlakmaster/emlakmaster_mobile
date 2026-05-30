import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_consultant_filter.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';

class EkipDetayHealthStrip {
  const EkipDetayHealthStrip({
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.interventionMembers,
    required this.teamNeedsIntervention,
    this.officeOpenTasks = 0,
    this.officeFollowUpQueue = 0,
    this.officeMissedCalls = 0,
    this.hasOfficeSignals = false,
  });

  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final int interventionMembers;
  final bool teamNeedsIntervention;
  final int officeOpenTasks;
  final int officeFollowUpQueue;
  final int officeMissedCalls;
  final bool hasOfficeSignals;
}

class EkipDetaySnapshot {
  const EkipDetaySnapshot({
    required this.team,
    required this.members,
    required this.strip,
    required this.stats,
    required this.managerName,
    required this.managerRoleLabel,
  });

  final TeamDoc team;
  final List<UserDoc> members;
  final EkipDetayHealthStrip strip;
  final EkiplerTeamRosterStats stats;
  final String? managerName;
  final String managerRoleLabel;
}

List<UserDoc> sortEkipDetayMembers(List<UserDoc> members) {
  final list = List<UserDoc>.from(members);
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

EkipDetayHealthStrip computeEkipDetayHealthStrip({
  required EkiplerTeamRosterStats stats,
  required int interventionMembers,
  AdminOfficeHealthSummary office = AdminOfficeHealthSummary.empty,
  bool includeOfficeSignals = true,
}) {
  final hasOffice = includeOfficeSignals && office.hasAny;
  return EkipDetayHealthStrip(
    totalMembers: stats.totalMembers,
    activeMembers: stats.activeMembers,
    inactiveMembers: stats.inactiveMembers,
    interventionMembers: interventionMembers,
    teamNeedsIntervention: stats.needsIntervention,
    officeOpenTasks: hasOffice ? office.openTasks : 0,
    officeFollowUpQueue: hasOffice ? office.followUpQueue : 0,
    officeMissedCalls: hasOffice ? office.missedCalls : 0,
    hasOfficeSignals: hasOffice,
  );
}

EkipDetaySnapshot computeEkipDetaySnapshot({
  required TeamDoc team,
  required List<UserDoc> consultants,
  AdminOfficeHealthSummary office = AdminOfficeHealthSummary.empty,
  bool includeOfficeSignals = true,
}) {
  final stats = computeTeamRosterStats(team: team, consultants: consultants);
  UserDoc? managerDoc;
  for (final u in consultants) {
    if (u.uid == team.managerId) {
      managerDoc = u;
      break;
    }
  }
  final managerName = managerDoc?.name ?? managerDoc?.email;
  final managerRoleLabel = managerDoc != null
      ? AppRole.fromFirestoreRole(managerDoc.role).label
      : 'Yönetici';

  final members = sortEkipDetayMembers(
    consultants.where((u) => u.teamId == team.id).toList(growable: false),
  );
  final interventionMembers =
      members.where(kadroNeedsIntervention).length;

  return EkipDetaySnapshot(
    team: team,
    members: members,
    stats: stats,
    managerName: managerName,
    managerRoleLabel: managerRoleLabel,
    strip: computeEkipDetayHealthStrip(
      stats: stats,
      interventionMembers: interventionMembers,
      office: office,
      includeOfficeSignals: includeOfficeSignals,
    ),
  );
}
