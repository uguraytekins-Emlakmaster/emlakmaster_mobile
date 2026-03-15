import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeaturePermission', () {
    group('canViewAllCalls', () {
      test('superAdmin can view all calls', () {
        expect(FeaturePermission.canViewAllCalls(AppRole.superAdmin), isTrue);
      });
      test('officeManager can view all calls', () {
        expect(FeaturePermission.canViewAllCalls(AppRole.officeManager), isTrue);
      });
      test('agent cannot view all calls', () {
        expect(FeaturePermission.canViewAllCalls(AppRole.agent), isFalse);
      });
      test('guest cannot view all calls', () {
        expect(FeaturePermission.canViewAllCalls(AppRole.guest), isFalse);
      });
      test('investorPortal cannot view all calls', () {
        expect(FeaturePermission.canViewAllCalls(AppRole.investorPortal), isFalse);
      });
      test('operations can view all calls', () {
        expect(FeaturePermission.canViewAllCalls(AppRole.operations), isTrue);
      });
    });

    group('canManageSettings', () {
      test('superAdmin can manage settings', () {
        expect(FeaturePermission.canManageSettings(AppRole.superAdmin), isTrue);
      });
      test('agent cannot manage settings', () {
        expect(FeaturePermission.canManageSettings(AppRole.agent), isFalse);
      });
    });

    group('canViewCallCenter', () {
      test('agent can view call center (own)', () {
        expect(FeaturePermission.canViewCallCenter(AppRole.agent), isTrue);
      });
    });
  });

  group('AppRole.fromId', () {
    test('null returns guest', () {
      expect(AppRole.fromId(null), AppRole.guest);
    });
    test('empty string returns guest', () {
      expect(AppRole.fromId(''), AppRole.guest);
    });
    test('agent id returns agent', () {
      expect(AppRole.fromId('agent'), AppRole.agent);
    });
    test('unknown id returns guest', () {
      expect(AppRole.fromId('unknown_role'), AppRole.guest);
    });
  });

  group('AppRole.fromFirestoreRole', () {
    test('broker maps to brokerOwner', () {
      expect(AppRole.fromFirestoreRole('broker'), AppRole.brokerOwner);
    });
    test('investor maps to investorPortal', () {
      expect(AppRole.fromFirestoreRole('investor'), AppRole.investorPortal);
    });
    test('super_admin maps to superAdmin', () {
      expect(AppRole.fromFirestoreRole('super_admin'), AppRole.superAdmin);
    });
    test('agent maps to agent', () {
      expect(AppRole.fromFirestoreRole('agent'), AppRole.agent);
    });
    test('null returns guest', () {
      expect(AppRole.fromFirestoreRole(null), AppRole.guest);
    });
  });
}
