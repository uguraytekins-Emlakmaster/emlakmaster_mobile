import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_access_state.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_invite_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfficeRole', () {
    test('toAppRole maps owner to brokerOwner', () {
      expect(OfficeRole.owner.toAppRole(), AppRole.brokerOwner);
      expect(OfficeRole.admin.toAppRole(), AppRole.officeManager);
      expect(OfficeRole.manager.toAppRole(), AppRole.teamLead);
      expect(OfficeRole.consultant.toAppRole(), AppRole.agent);
    });

    test('parseOfficeRole handles values', () {
      expect(parseOfficeRole('owner'), OfficeRole.owner);
      expect(parseOfficeRole('ADMIN'), OfficeRole.admin);
      expect(parseOfficeRole('bad'), isNull);
    });
  });

  group('OfficeInvite', () {
    test('isExpired respects expiresAt', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final inv = OfficeInvite(
        id: '1',
        officeId: 'o',
        code: 'ABC',
        createdBy: 'u',
        expiresAt: past,
        maxUses: 1,
        usedCount: 0,
        roleToAssign: OfficeRole.consultant,
      );
      expect(inv.isExpired, isTrue);
    });

    test('isExhausted when usedCount >= maxUses', () {
      const inv = OfficeInvite(
        id: '1',
        officeId: 'o',
        code: 'ABC',
        createdBy: 'u',
        maxUses: 2,
        usedCount: 2,
        roleToAssign: OfficeRole.consultant,
      );
      expect(inv.isExhausted, isTrue);
    });
  });

  group('deriveOfficeAccessState', () {
    const userNoOffice = UserDoc(uid: 'u1', role: 'agent');
    const userWithOffice = UserDoc(uid: 'u1', role: 'agent', officeId: 'o1');

    test('no officeId → noOfficeContext', () {
      expect(
        deriveOfficeAccessState(
          userDoc: userNoOffice,
          primaryMembership: null,
          userDocLoading: false,
          membershipLoading: false,
        ),
        OfficeAccessState.noOfficeContext,
      );
    });

    test('officeId but no membership doc → membershipMissing', () {
      expect(
        deriveOfficeAccessState(
          userDoc: userWithOffice,
          primaryMembership: null,
          userDocLoading: false,
          membershipLoading: false,
        ),
        OfficeAccessState.membershipMissing,
      );
    });

    test('active membership → officeReady', () {
      const m = OfficeMembership(
        id: 'u1_o1',
        officeId: 'o1',
        userId: 'u1',
        role: OfficeRole.consultant,
        status: MembershipStatus.active,
      );
      expect(
        deriveOfficeAccessState(
          userDoc: userWithOffice,
          primaryMembership: m,
          userDocLoading: false,
          membershipLoading: false,
        ),
        OfficeAccessState.officeReady,
      );
    });

    test('officeId mismatch → inconsistentPointer', () {
      const m = OfficeMembership(
        id: 'u1_o2',
        officeId: 'o2',
        userId: 'u1',
        role: OfficeRole.consultant,
        status: MembershipStatus.active,
      );
      expect(
        deriveOfficeAccessState(
          userDoc: userWithOffice,
          primaryMembership: m,
          userDocLoading: false,
          membershipLoading: false,
        ),
        OfficeAccessState.inconsistentPointer,
      );
    });
  });
}
