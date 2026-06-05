import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:flutter_test/flutter_test.dart';

/// Router seviyesi derinlemesine savunma: yönetici-yalnız rotalara danışman/guest
/// ASLA giremez; gerçek yönetici tier her zaman geçer. Bu testler bir debug
/// override'ın yetki yükseltmesini engelleyen kontratı kilitler.
void main() {
  const managerPaths = <String>[
    AppRouter.routeCommandCenter,
    AppRouter.routeWarRoom,
    AppRouter.routeBrokerCommand,
    '/admin/teams',
    '/admin/anything',
  ];

  const nonManagerRoles = <AppRole>[AppRole.agent, AppRole.guest];

  const managerRoles = <AppRole>[
    AppRole.superAdmin,
    AppRole.brokerOwner,
    AppRole.generalManager,
    AppRole.officeManager,
    AppRole.teamLead,
  ];

  group('isManagerOnlyPath', () {
    test('yönetici rotalarını tanır', () {
      for (final p in managerPaths) {
        expect(AppRouter.isManagerOnlyPath(p), isTrue, reason: p);
      }
    });

    test('danışman/genel rotaları yönetici-yalnız DEĞİL', () {
      for (final p in <String>['/', '/customer/1', '/calls', '/messages']) {
        expect(AppRouter.isManagerOnlyPath(p), isFalse, reason: p);
      }
    });
  });

  group('managerOnlyGuard', () {
    test('danışman/guest yönetici rotasından home\'a yönlenir', () {
      for (final role in nonManagerRoles) {
        for (final path in managerPaths) {
          expect(
            AppRouter.managerOnlyGuard(role, path),
            AppRouter.routeHome,
            reason: '$role $path → home olmalı',
          );
        }
      }
    });

    test('gerçek yönetici tier her yönetici rotasına girer (yönlendirme yok)',
        () {
      for (final role in managerRoles) {
        for (final path in managerPaths) {
          expect(
            AppRouter.managerOnlyGuard(role, path),
            isNull,
            reason: '$role $path → yönlendirme olmamalı',
          );
        }
      }
    });

    test('null rol yönlendirmez (auth katmanı devralır)', () {
      expect(AppRouter.managerOnlyGuard(null, AppRouter.routeCommandCenter),
          isNull);
    });

    test('danışman, yönetici-olmayan rotada serbest', () {
      expect(AppRouter.managerOnlyGuard(AppRole.agent, '/calls'), isNull);
      expect(AppRouter.managerOnlyGuard(AppRole.agent, '/customer/9'), isNull);
    });
  });
}
