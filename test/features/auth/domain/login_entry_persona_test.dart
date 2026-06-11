import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginEntryPersona', () {
    test('fromId round-trips persona id', () {
      for (final persona in LoginEntryPersona.values) {
        expect(LoginEntryPersona.fromId(persona.id), persona);
      }
      expect(LoginEntryPersona.fromId('unknown'), isNull);
      expect(LoginEntryPersona.fromId(null), isNull);
    });

    test('fromRole maps manager roles to manager persona', () {
      expect(
        LoginEntryPersona.fromRole(AppRole.officeManager),
        LoginEntryPersona.manager,
      );
      expect(
        LoginEntryPersona.fromRole(AppRole.teamLead),
        LoginEntryPersona.manager,
      );
    });

    test('fromRole maps agent roles to consultant persona', () {
      expect(
        LoginEntryPersona.fromRole(AppRole.agent),
        LoginEntryPersona.consultant,
      );
    });

    test('matchesRole respects manager role set', () {
      expect(
        LoginEntryPersona.manager.matchesRole(AppRole.brokerOwner),
        isTrue,
      );
      expect(
        LoginEntryPersona.consultant.matchesRole(AppRole.brokerOwner),
        isFalse,
      );
      expect(
        LoginEntryPersona.consultant.matchesRole(AppRole.agent),
        isTrue,
      );
    });

    test('filterSelectableRoles keeps only matching roles', () {
      const all = AppRole.values;
      final managerRoles =
          LoginEntryPersona.manager.filterSelectableRoles(all);
      final consultantRoles =
          LoginEntryPersona.consultant.filterSelectableRoles(all);

      expect(managerRoles, isNotEmpty);
      expect(consultantRoles, isNotEmpty);
      // super_admin hiçbir personada görünmez.
      expect(managerRoles, isNot(contains(AppRole.superAdmin)));
      expect(consultantRoles, isNot(contains(AppRole.superAdmin)));
      for (final role in managerRoles) {
        expect(LoginEntryPersona.manager.matchesRole(role), isTrue);
      }
      for (final role in consultantRoles) {
        expect(LoginEntryPersona.consultant.matchesRole(role), isTrue);
      }
    });
  });
}
