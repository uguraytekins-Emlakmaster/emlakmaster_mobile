import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_consultant_filter.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';

/// Kadro üst şeridi — roster + ofis özeti (etiketler UI'da ayrışır).
class KadroHealthStrip {
  const KadroHealthStrip({
    required this.activeConsultants,
    required this.needsIntervention,
    required this.inactiveConsultants,
    required this.teamCount,
    required this.unassignedConsultants,
    this.officeOpenTasks = 0,
    this.officeFollowUpQueue = 0,
    this.officeMissedCalls = 0,
    this.officeEscalations = 0,
    this.hasOfficeSignals = false,
  });

  final int activeConsultants;
  final int needsIntervention;
  final int inactiveConsultants;
  final int teamCount;
  final int unassignedConsultants;
  final int officeOpenTasks;
  final int officeFollowUpQueue;
  final int officeMissedCalls;
  final int officeEscalations;
  final bool hasOfficeSignals;

  static const empty = KadroHealthStrip(
    activeConsultants: 0,
    needsIntervention: 0,
    inactiveConsultants: 0,
    teamCount: 0,
    unassignedConsultants: 0,
  );
}

class KadroPageSnapshot {
  const KadroPageSnapshot({
    required this.consultants,
    required this.teams,
    required this.strip,
    required this.teamNames,
  });

  final List<UserDoc> consultants;
  final List<TeamDoc> teams;
  final KadroHealthStrip strip;
  final Map<String, String> teamNames;
}

KadroHealthStrip computeKadroHealthStrip({
  required List<UserDoc> consultants,
  required List<TeamDoc> teams,
  AdminOfficeHealthSummary office = AdminOfficeHealthSummary.empty,
  bool includeOfficeSignals = true,
}) {
  var active = 0;
  var inactive = 0;
  var unassigned = 0;
  var intervention = 0;

  for (final u in consultants) {
    if (u.isActive) {
      active++;
    } else {
      inactive++;
    }
    final tid = u.teamId;
    if (tid == null || tid.isEmpty) unassigned++;
    if (kadroNeedsIntervention(u)) intervention++;
  }

  final hasOffice = includeOfficeSignals && office.hasAny;

  return KadroHealthStrip(
    activeConsultants: active,
    needsIntervention: intervention,
    inactiveConsultants: inactive,
    teamCount: teams.length,
    unassignedConsultants: unassigned,
    officeOpenTasks: hasOffice ? office.openTasks : 0,
    officeFollowUpQueue: hasOffice ? office.followUpQueue : 0,
    officeMissedCalls: hasOffice ? office.missedCalls : 0,
    officeEscalations: hasOffice
        ? office.criticalEscalations + office.escalations
        : 0,
    hasOfficeSignals: hasOffice,
  );
}

KadroPageSnapshot computeKadroPageSnapshot({
  required List<UserDoc> consultants,
  required List<TeamDoc> teams,
  AdminOfficeHealthSummary office = AdminOfficeHealthSummary.empty,
  bool includeOfficeSignals = true,
}) {
  return KadroPageSnapshot(
    consultants: consultants,
    teams: teams,
    strip: computeKadroHealthStrip(
      consultants: consultants,
      teams: teams,
      office: office,
      includeOfficeSignals: includeOfficeSignals,
    ),
    teamNames: {for (final t in teams) t.id: t.name},
  );
}
