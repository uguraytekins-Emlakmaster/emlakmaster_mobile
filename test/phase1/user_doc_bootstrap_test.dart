import 'package:emlakmaster_mobile/core/permissions/permission_id.dart';
import 'package:emlakmaster_mobile/core/permissions/role_permission_registry.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_capability.dart';
import 'package:emlakmaster_mobile/features/external_integrations/application/integration_capability_registry.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RolePermissionRegistry', () {
    test('superAdmin has manageOfficeSettings', () {
      expect(
        RolePermissionRegistry.has(AppRole.superAdmin, PermissionId.manageOfficeSettings),
        isTrue,
      );
    });

    test('guest has no permissions', () {
      expect(RolePermissionRegistry.forRole(AppRole.guest), isEmpty);
    });

    test('agent has manageOwnListings', () {
      expect(
        RolePermissionRegistry.has(AppRole.agent, PermissionId.manageOwnListings),
        isTrue,
      );
    });
  });

  group('IntegrationCapabilityRegistry', () {
    test('all platforms expose Phase 1 import flags honestly', () {
      for (final p in IntegrationPlatformId.values) {
        final c = IntegrationCapabilityRegistry.forPlatform(p);
        expect(c.canUseUrlImport, isTrue);
        expect(c.canUseBrowserExtension, isTrue);
        expect(c.supportLevel, IntegrationSupportLevel.tier2UserControlled);
      }
    });
  });

  group('IntegrationCapabilitySet JSON', () {
    test('roundtrip preserves new keys', () {
      const original = IntegrationCapabilitySet(
        canUseUrlImport: true,
        hasOfficialSupport: true,
        supportLevel: IntegrationSupportLevel.tier1Official,
      );
      final json = original.toJson();
      final back = IntegrationCapabilitySet.fromJson(json);
      expect(back.canUseUrlImport, isTrue);
      expect(back.hasOfficialSupport, isTrue);
      expect(back.supportLevel, IntegrationSupportLevel.tier1Official);
    });
  });
}
