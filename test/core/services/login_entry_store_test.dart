import 'package:emlakmaster_mobile/core/services/login_entry_store.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginEntryStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists and reloads persona', () async {
      final store = LoginEntryStore.instance;
      await store.clearPersona();

      await store.setPersona(LoginEntryPersona.manager);
      expect(await store.loadPersona(), LoginEntryPersona.manager);
      expect(store.personaSync, LoginEntryPersona.manager);

      await store.setPersona(LoginEntryPersona.consultant);
      expect(await store.loadPersona(), LoginEntryPersona.consultant);
    });

    test('clearPersona removes saved value', () async {
      final store = LoginEntryStore.instance;
      await store.setPersona(LoginEntryPersona.manager);
      await store.clearPersona();

      expect(await store.loadPersona(), isNull);
      expect(store.personaSync, isNull);
    });
  });
}
