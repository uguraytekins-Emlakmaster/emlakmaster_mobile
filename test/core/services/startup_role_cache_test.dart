import 'package:emlakmaster_mobile/core/services/startup_role_cache.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StartupRoleCache.instance.clear();
  });

  test('persist and restore role for same uid', () async {
    await StartupRoleCache.instance.warmUp();
    await StartupRoleCache.instance.persist('uid-1', AppRole.agent);

    await StartupRoleCache.instance.warmUp();
    expect(StartupRoleCache.instance.roleForUser('uid-1'), AppRole.agent);
    expect(StartupRoleCache.instance.roleForUser('uid-2'), isNull);
  });

  test('clear removes cached role', () async {
    await StartupRoleCache.instance.persist('uid-1', AppRole.client);
    await StartupRoleCache.instance.clear();
    await StartupRoleCache.instance.warmUp();
    expect(StartupRoleCache.instance.roleForUser('uid-1'), isNull);
  });
}
