import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:flutter_test/flutter_test.dart';

/// Güvenlik regresyonu: herkese açık rol-seçim ekranı, self-service bir
/// kullanıcının kendine yönetici/admin rolü atamasına ASLA izin vermemeli.
/// Yönetici statüsü yalnızca ofis oluşturma (→ broker_owner) veya ofis daveti
/// (→ manager/admin) ile gelir. super_admin hiçbir koşulda istemciden atanamaz
/// — platform sahibi rolü yalnızca sunucu tarafında tanımlıdır.
void main() {
  const adminTiers = <AppRole>[
    AppRole.superAdmin,
    AppRole.brokerOwner,
    AppRole.generalManager,
    AppRole.officeManager,
    AppRole.teamLead,
  ];

  group('selfServiceSelectableRoles', () {
    test('yalnızca agent atanabilir (yönetici/admin yok)', () {
      final roles = selfServiceSelectableRoles();
      expect(roles, [AppRole.agent]);
      for (final admin in adminTiers) {
        expect(roles, isNot(contains(admin)),
            reason: '$admin self-service ile atanamamalı');
      }
    });

    test('super_admin hiçbir koşulda listede yok', () {
      expect(
        selfServiceSelectableRoles(),
        isNot(contains(AppRole.superAdmin)),
      );
    });
  });

  group('persona seçimi daraltır', () {
    test('danışman persona yalnızca agent görür', () {
      final picked = LoginEntryPersona.consultant
          .filterSelectableRoles(selfServiceSelectableRoles());
      expect(picked, [AppRole.agent]);
    });

    test('yönetici persona broker_owner\'a ULAŞAMAZ (ofis kurmalı)', () {
      final picked = LoginEntryPersona.manager
          .filterSelectableRoles(selfServiceSelectableRoles());
      expect(picked, isNot(contains(AppRole.brokerOwner)));
      expect(picked, [AppRole.agent]);
    });

    test('super_admin tam rol listesi verilse bile elenir', () {
      for (final persona in LoginEntryPersona.values) {
        final picked = persona.filterSelectableRoles(AppRole.values);
        expect(picked, isNot(contains(AppRole.superAdmin)),
            reason: 'persona=$persona');
      }
    });
  });
}
