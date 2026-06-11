import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/app_destinations.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _l10n = AppLocalizations(const Locale('tr'));

Set<String> _ids(List<AppDestination> d) => d.map((e) => e.id).toSet();

/// Bilinen, gerçek (router'da tanımlı) tam sayfa rotalar.
const _knownRoutes = <String>{
  AppRouter.routeOfficeAdmin,
  AppRouter.routeOfficeInviteCreate,
  AppRouter.routeBrokerCommand,
  AppRouter.routeCommandCenter,
  AppRouter.routeWarRoom,
};

void main() {
  group('appDestinationsFor — rol farkındalığı', () {
    test('danışman (agent) kendi kabuk sekmelerini görür', () {
      final ids = _ids(appDestinationsFor(AppRole.agent, _l10n));
      expect(ids, containsAll(<String>{
        'home',
        'my_calls',
        'my_customers',
        'listings',
        'follow_up',
        'my_tasks',
        'settings',
      }));
      // Admin-only ve müşteri-only alanlar YOK.
      expect(ids, isNot(contains('office_admin')));
      expect(ids, isNot(contains('war_room')));
      expect(ids, isNot(contains('command_center')));
      expect(ids, isNot(contains('favorites')));
    });

    test('tam yetkili admin (brokerOwner) komuta + savaş odasını görür', () {
      final ids = _ids(appDestinationsFor(AppRole.brokerOwner, _l10n));
      expect(ids, containsAll(<String>{
        'home',
        'office_admin',
        'office_invite',
        'command_center',
        'war_room',
        'operations_deck',
        'settings',
      }));
      // Danışman/müşteri sekmeleri YOK.
      expect(ids, isNot(contains('my_customers')));
      expect(ids, isNot(contains('favorites')));
    });

    test(
        'kısıtlı admin (officeManager) çağrı merkezini görmez ama savaş odasını görür',
        () {
      final ids = _ids(appDestinationsFor(AppRole.officeManager, _l10n));
      // canViewAllCalls yalnızca superAdmin/brokerOwner → command_center omitted.
      expect(ids, isNot(contains('command_center')));
      // isManagerTier → war_room var.
      expect(ids, contains('war_room'));
      expect(ids, contains('office_admin'));
    });
  });

  group('bütünlük (honesty / no dead routes)', () {
    for (final role in AppRole.values) {
      test('${role.id}: her hedef gerçek + tutarlı', () {
        final dests = appDestinationsFor(role, _l10n);
        expect(dests, isNotEmpty);

        // Benzersiz id.
        expect(_ids(dests).length, dests.length,
            reason: 'duplicate destination id for ${role.id}');

        for (final d in dests) {
          switch (d.nav) {
            case AppDestinationNav.route:
              expect(d.route, isNotNull);
              expect(d.shortcut, isNull);
              expect(d.route!, startsWith('/'));
              expect(_knownRoutes, contains(d.route),
                  reason: '${d.id} rota router\'da tanımlı olmalı');
            case AppDestinationNav.shortcut:
              expect(d.shortcut, isNotNull);
              expect(d.route, isNull);
              expect(MainShellShortcut.values, contains(d.shortcut));
          }
          expect(d.label.trim(), isNotEmpty);
        }
      });
    }
  });

  group('filterDestinations', () {
    test('boş sorgu tümünü döner', () {
      final all = appDestinationsFor(AppRole.agent, _l10n);
      expect(filterDestinations(all, ''), hasLength(all.length));
      expect(filterDestinations(all, '   '), hasLength(all.length));
    });

    test('etikete göre daraltır (case-insensitive)', () {
      final all = appDestinationsFor(AppRole.agent, _l10n);
      final target = all.first;
      final result = filterDestinations(all, target.label.toUpperCase());
      expect(result.map((e) => e.id), contains(target.id));
    });

    test('eşleşmeyen sorgu boş döner', () {
      final all = appDestinationsFor(AppRole.agent, _l10n);
      expect(filterDestinations(all, 'zzzz_no_match_qq'), isEmpty);
    });
  });
}
