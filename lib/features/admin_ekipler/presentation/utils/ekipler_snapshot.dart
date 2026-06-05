import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';

class EkiplerTeamRosterStats {
  const EkiplerTeamRosterStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.isEmpty,
    required this.allMembersInactive,
    required this.needsIntervention,
    required this.hasManager,
  });

  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final bool isEmpty;
  final bool allMembersInactive;
  final bool needsIntervention;
  final bool hasManager;

  bool get hasEmptyOrPressure =>
      isEmpty ||
      allMembersInactive ||
      (inactiveMembers > 0 && inactiveMembers >= activeMembers);
}

class EkiplerTeamViewModel {
  const EkiplerTeamViewModel({
    required this.team,
    required this.stats,
    required this.managerName,
    required this.managerRoleLabel,
  });

  final TeamDoc team;
  final EkiplerTeamRosterStats stats;
  final String? managerName;
  final String managerRoleLabel;
}

class EkiplerHealthStrip {
  const EkiplerHealthStrip({
    required this.activeTeams,
    required this.totalConsultants,
    required this.interventionTeams,
    required this.unassignedConsultants,
    this.officeOpenTasks = 0,
    this.officeFollowUpQueue = 0,
    this.officeMissedCalls = 0,
    this.hasOfficeSignals = false,
  });

  final int activeTeams;
  final int totalConsultants;
  final int interventionTeams;
  final int unassignedConsultants;
  final int officeOpenTasks;
  final int officeFollowUpQueue;
  final int officeMissedCalls;
  final bool hasOfficeSignals;

  static const empty = EkiplerHealthStrip(
    activeTeams: 0,
    totalConsultants: 0,
    interventionTeams: 0,
    unassignedConsultants: 0,
  );
}

class EkiplerPageSnapshot {
  const EkiplerPageSnapshot({
    required this.teams,
    required this.unassignedConsultants,
    required this.strip,
    required this.managerNames,
  });

  final List<EkiplerTeamViewModel> teams;
  final List<UserDoc> unassignedConsultants;
  final EkiplerHealthStrip strip;
  final Map<String, String> managerNames;
}

EkiplerTeamRosterStats computeTeamRosterStats({
  required TeamDoc team,
  required List<UserDoc> consultants,
}) {
  final members =
      consultants.where((u) => u.teamId == team.id).toList(growable: false);
  var active = 0;
  var inactive = 0;
  for (final m in members) {
    if (m.isActive) {
      active++;
    } else {
      inactive++;
    }
  }

  final isEmpty = members.isEmpty;
  final allInactive = !isEmpty && active == 0;
  final hasManager = team.managerId.isNotEmpty;

  final needsIntervention = isEmpty || allInactive || !hasManager;

  return EkiplerTeamRosterStats(
    totalMembers: members.length,
    activeMembers: active,
    inactiveMembers: inactive,
    isEmpty: isEmpty,
    allMembersInactive: allInactive,
    needsIntervention: needsIntervention,
    hasManager: hasManager,
  );
}

EkiplerHealthStrip computeEkiplerHealthStrip({
  required List<EkiplerTeamViewModel> teams,
  required List<UserDoc> consultants,
  AdminOfficeHealthSummary office = AdminOfficeHealthSummary.empty,
  bool includeOfficeSignals = true,
}) {
  var activeTeams = 0;
  var interventionTeams = 0;
  var assignedActive = 0;
  var unassigned = 0;

  for (final t in teams) {
    if (t.stats.activeMembers > 0) activeTeams++;
    if (t.stats.needsIntervention) interventionTeams++;
  }

  for (final u in consultants) {
    final tid = u.teamId;
    if (tid == null || tid.isEmpty) {
      unassigned++;
    } else if (u.isActive) {
      assignedActive++;
    }
  }

  final hasOffice = includeOfficeSignals && office.hasAny;

  return EkiplerHealthStrip(
    activeTeams: activeTeams,
    totalConsultants: assignedActive,
    interventionTeams: interventionTeams,
    unassignedConsultants: unassigned,
    officeOpenTasks: hasOffice ? office.openTasks : 0,
    officeFollowUpQueue: hasOffice ? office.followUpQueue : 0,
    officeMissedCalls: hasOffice ? office.missedCalls : 0,
    hasOfficeSignals: hasOffice,
  );
}

EkiplerPageSnapshot computeEkiplerPageSnapshot({
  required List<TeamDoc> teams,
  required List<UserDoc> consultants,
  AdminOfficeHealthSummary office = AdminOfficeHealthSummary.empty,
  bool includeOfficeSignals = true,
}) {
  final managerNames = <String, String>{};
  for (final u in consultants) {
    managerNames[u.uid] = u.name ?? u.email ?? u.uid;
  }

  final teamViews = teams.map((team) {
    final manager = managerNames[team.managerId];
    UserDoc? managerDoc;
    for (final u in consultants) {
      if (u.uid == team.managerId) {
        managerDoc = u;
        break;
      }
    }
    final roleLabel = managerDoc != null
        ? AppRole.fromFirestoreRole(managerDoc.role).label
        : 'Yönetici';

    return EkiplerTeamViewModel(
      team: team,
      stats: computeTeamRosterStats(team: team, consultants: consultants),
      managerName: manager,
      managerRoleLabel: roleLabel,
    );
  }).toList();

  final unassigned = consultants.where((u) {
    final tid = u.teamId;
    return tid == null || tid.isEmpty;
  }).toList(growable: false);

  return EkiplerPageSnapshot(
    teams: teamViews,
    unassignedConsultants: unassigned,
    strip: computeEkiplerHealthStrip(
      teams: teamViews,
      consultants: consultants,
      office: office,
      includeOfficeSignals: includeOfficeSignals,
    ),
    managerNames: managerNames,
  );
}
