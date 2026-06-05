import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_consultant_filter.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_snapshot.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:flutter_test/flutter_test.dart';

UserDoc _user({
  required String uid,
  String? name,
  String? email,
  String role = 'agent',
  bool isActive = true,
  String? teamId,
}) {
  return UserDoc(
    uid: uid,
    role: role,
    name: name,
    email: email,
    isActive: isActive,
    teamId: teamId,
  );
}

void main() {
  group('kadro consultant filter', () {
    final roster = [
      _user(uid: 'a', name: 'Ali Veli', teamId: 't1', isActive: true),
      _user(uid: 'b', name: 'Burak', teamId: null, isActive: true),
      _user(uid: 'c', name: 'Cem', teamId: 't2', isActive: false),
    ];

    test('search matches name and email', () {
      final out = filterKadroConsultants(
        source: roster,
        searchQuery: 'ali',
        filter: KadroRosterFilter.all,
      );
      expect(out.map((e) => e.uid), ['a']);
    });

    test('intervention filter selects inactive or unassigned', () {
      final out = filterKadroConsultants(
        source: roster,
        searchQuery: '',
        filter: KadroRosterFilter.intervention,
      );
      expect(out.map((e) => e.uid), containsAll(['b', 'c']));
      expect(out.length, 2);
    });

    test('byTeam filter respects team id', () {
      final out = filterKadroConsultants(
        source: roster,
        searchQuery: '',
        filter: KadroRosterFilter.byTeam,
        teamId: 't1',
      );
      expect(out.map((e) => e.uid), ['a']);
    });

    test('group by team creates unassigned section', () {
      final sections = groupKadroByTeam(
        consultants: roster,
        teams: const [
          TeamDoc(id: 't1', name: 'Alpha', managerId: 'm1'),
          TeamDoc(id: 't2', name: 'Beta', managerId: 'm2'),
        ],
      );
      expect(sections.length, 3);
      expect(sections.last.teamName, 'Atanmamış');
    });
  });

  group('kadro snapshot', () {
    test('compute strip uses roster and office signals honestly', () {
      final strip = computeKadroHealthStrip(
        consultants: [
          _user(uid: '1', teamId: 't1'),
          _user(uid: '2', teamId: null),
          _user(uid: '3', isActive: false),
        ],
        teams: const [TeamDoc(id: 't1', name: 'Alpha', managerId: 'm1')],
        office: const AdminOfficeHealthSummary(
          openTasks: 4,
          followUpQueue: 2,
          missedCalls: 1,
          escalations: 1,
        ),
        includeOfficeSignals: true,
      );

      expect(strip.activeConsultants, 2);
      expect(strip.needsIntervention, 2);
      expect(strip.teamCount, 1);
      expect(strip.officeOpenTasks, 4);
      expect(strip.hasOfficeSignals, isTrue);
    });
  });
}
