import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:flutter_test/flutter_test.dart';

/// Güvenlik regresyonu: herkese açık rol-seçim ekranı, self-service bir kullanıcının
/// kendine yönetici/admin rolü atamasına ASLA izin vermemeli. Yönetici statüsü yalnızca
/// ofis oluşturma (→ broker_owner) veya ofis daveti (→ manager/admin) ile gelir. Tek
/// istisna sistemin ilk kullanıcısıdır (kurucu bootstrap).
void main() {
  const adminTiers = <AppRole>[
    AppRole.superAdmin,
    AppRole.brokerOwner,
    AppRole.generalManager,
    AppRole.officeManager,
    AppRole.teamLead,
  ];

  group('selfServiceSelectableRoles', () {
    test('non-founder yalnızca agent atayabilir (yönetici/admin yok)', () {
      final roles = selfServiceSelectableRoles(isFoundingUser: false);
      expect(roles, [AppRole.agent]);
      for (final admin in adminTiers) {
        expect(roles, isNot(contains(admin)),
            reason: '$admin self-service ile atanamamalı');
      }
    });

    test('founder (boş sistem) admin kademesini bootstrap edebilir', () {
      final roles = selfServiceSelectableRoles(isFoundingUser: true);
      expect(roles, contains(AppRole.superAdmin));
      expect(roles, contains(AppRole.brokerOwner));
      expect(roles, isNot(contains(AppRole.guest)));
    });
  });

  group('persona seçimi daraltır', () {
    test('danışman persona her durumda yalnızca agent', () {
      for (final founding in [true, false]) {
        final all = selfServiceSelectableRoles(isFoundingUser: founding);
        final picked = LoginEntryPersona.consultant
            .filterSelectableRoles(all, includeSuperAdmin: founding);
        expect(picked, [AppRole.agent], reason: 'founding=$founding');
      }
    });

    test('yönetici persona non-founder için broker_owner\'a ULAŞAMAZ', () {
      final all = selfServiceSelectableRoles(isFoundingUser: false);
      final picked = LoginEntryPersona.manager
          .filterSelectableRoles(all, includeSuperAdmin: false);
      expect(picked, isNot(contains(AppRole.brokerOwner)));
      expect(picked, [AppRole.agent]);
    });

    test('yönetici persona broker_owner\'ı yalnızca kurucuda seçebilir', () {
      final all = selfServiceSelectableRoles(isFoundingUser: true);
      final picked = LoginEntryPersona.manager
          .filterSelectableRoles(all, includeSuperAdmin: true);
      expect(picked, contains(AppRole.brokerOwner));
    });
  });
}
