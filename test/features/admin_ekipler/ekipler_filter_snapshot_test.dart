import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_team_filter.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:flutter_test/flutter_test.dart';

UserDoc _user({
  required String uid,
  String? name,
  String role = 'agent',
  bool isActive = true,
  String? teamId,
}) {
  return UserDoc(
    uid: uid,
    role: role,
    name: name,
    isActive: isActive,
    teamId: teamId,
  );
}

TeamDoc _team({required String id, String name = 'Team', String managerId = 'm1'}) {
  return TeamDoc(id: id, name: name, managerId: managerId);
}

void main() {
  group('ekipler team filter', () {
    final snapshot = computeEkiplerPageSnapshot(
      teams: [
        _team(id: 't1', name: 'Alpha'),
        _team(id: 't2', name: 'Beta', managerId: ''),
        _team(id: 't3', name: 'Gamma'),
      ],
      consultants: [
        _user(uid: 'a1', name: 'Ali', teamId: 't1'),
        _user(uid: 'a2', name: 'Burak', teamId: 't1', isActive: false),
        _user(uid: 'u1', name: 'Unassigned'),
      ],
    );

    test('search matches team name and manager', () {
      final out = filterEkiplerTeams(
        source: snapshot.teams,
        searchQuery: 'alpha',
        filter: EkiplerTeamFilter.all,
      );
      expect(out.map((e) => e.team.id), ['t1']);
    });

    test('intervention filter selects empty or managerless teams', () {
      final out = filterEkiplerTeams(
        source: snapshot.teams,
        searchQuery: '',
        filter: EkiplerTeamFilter.intervention,
      );
      expect(out.map((e) => e.team.id), containsAll(['t2']));
    });

    test('unassigned filter returns empty team list', () {
      final out = filterEkiplerTeams(
        source: snapshot.teams,
        searchQuery: '',
        filter: EkiplerTeamFilter.unassigned,
      );
      expect(out, isEmpty);
    });

    test('filter unassigned consultants', () {
      final out = filterUnassignedConsultants(
        source: snapshot.unassignedConsultants,
        searchQuery: 'una',
      );
      expect(out.map((e) => e.uid), ['u1']);
    });
  });

  group('ekipler snapshot', () {
    test('compute team stats from consultant roster honestly', () {
      final stats = computeTeamRosterStats(
        team: _team(id: 't1'),
        consultants: [
          _user(uid: '1', teamId: 't1'),
          _user(uid: '2', teamId: 't1', isActive: false),
        ],
      );
      expect(stats.totalMembers, 2);
      expect(stats.activeMembers, 1);
      expect(stats.inactiveMembers, 1);
    });

    test('strip uses roster and office signals honestly', () {
      final page = computeEkiplerPageSnapshot(
        teams: [_team(id: 't1'), _team(id: 't2', managerId: '')],
        consultants: [
          _user(uid: '1', teamId: 't1'),
          _user(uid: '2'),
        ],
        office: const AdminOfficeHealthSummary(
          activeAdvisors: 2,
          openTasks: 5,
          liveCalls: 0,
          missedCalls: 1,
          officeAlerts: 0,
          highAlerts: 0,
          escalations: 0,
          criticalEscalations: 0,
          followUpQueue: 3,
          setupPending: 0,
          syncRisk: 0,
        ),
        includeOfficeSignals: true,
      );
      expect(page.strip.unassignedConsultants, 1);
      expect(page.strip.officeOpenTasks, 5);
      expect(page.strip.hasOfficeSignals, isTrue);
    });
  });
}
