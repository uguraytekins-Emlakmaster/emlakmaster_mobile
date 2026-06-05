import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/utils/ekip_detay_snapshot.dart';
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

TeamDoc _team({
  required String id,
  String name = 'Team',
  String managerId = 'm1',
}) {
  return TeamDoc(id: id, name: name, managerId: managerId);
}

void main() {
  group('ekip detay snapshot', () {
    test('derives roster from teamId join not memberIds', () {
      final team = _team(id: 't1', managerId: 'lead1');
      final consultants = [
        _user(uid: 'a1', name: 'Ali', teamId: 't1'),
        _user(uid: 'a2', name: 'Burak', teamId: 't1', isActive: false),
        _user(uid: 'lead1', name: 'Lead', role: 'team_lead', teamId: 't2'),
        _user(uid: 'x1', name: 'Other', teamId: 't2'),
      ];

      final snap = computeEkipDetaySnapshot(
        team: team,
        consultants: consultants,
      );

      expect(snap.members.map((e) => e.uid), ['a2', 'a1']);
      expect(snap.strip.totalMembers, 2);
      expect(snap.strip.activeMembers, 1);
      expect(snap.strip.interventionMembers, 1);
    });

    test('manager identity resolved from consultants', () {
      final snap = computeEkipDetaySnapshot(
        team: _team(id: 't1', managerId: 'm1'),
        consultants: [
          _user(uid: 'm1', name: 'Ayşe', role: 'team_lead', teamId: 't1'),
          _user(uid: 'a1', teamId: 't1'),
        ],
      );

      expect(snap.managerName, 'Ayşe');
      expect(snap.managerRoleLabel, isNotEmpty);
    });

    test('office signals included only when requested', () {
      const office = AdminOfficeHealthSummary(
        openTasks: 5,
        followUpQueue: 3,
        missedCalls: 1,
      );

      final withOffice = computeEkipDetaySnapshot(
        team: _team(id: 't1'),
        consultants: [_user(uid: 'a1', teamId: 't1')],
        office: office,
        includeOfficeSignals: true,
      );
      final withoutOffice = computeEkipDetaySnapshot(
        team: _team(id: 't1'),
        consultants: [_user(uid: 'a1', teamId: 't1')],
        office: office,
        includeOfficeSignals: false,
      );

      expect(withOffice.strip.hasOfficeSignals, isTrue);
      expect(withOffice.strip.officeOpenTasks, 5);
      expect(withoutOffice.strip.hasOfficeSignals, isFalse);
      expect(withoutOffice.strip.officeOpenTasks, 0);
    });

    test('team needs intervention when empty or managerless', () {
      final empty = computeEkipDetaySnapshot(
        team: _team(id: 't1', managerId: ''),
        consultants: const [],
      );
      expect(empty.strip.teamNeedsIntervention, isTrue);
      expect(empty.members, isEmpty);

      final noManager = computeEkipDetaySnapshot(
        team: _team(id: 't1', managerId: ''),
        consultants: [_user(uid: 'a1', teamId: 't1')],
      );
      expect(noManager.strip.teamNeedsIntervention, isTrue);
    });

    test('sort puts intervention members first', () {
      final sorted = sortEkipDetayMembers([
        _user(uid: 'ok', name: 'Zara', teamId: 't1'),
        _user(uid: 'bad', name: 'Ali', teamId: 't1', isActive: false),
      ]);
      expect(sorted.first.uid, 'bad');
    });
  });
}
