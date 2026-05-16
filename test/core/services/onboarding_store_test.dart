import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('instance is singleton', () {
      expect(OnboardingStore.instance, same(OnboardingStore.instance));
    });

    test('setCompleted persists and warmUp reads true', () async {
      final store = OnboardingStore.instance;
      await store.resetForTesting();
      expect(store.completedSync, isFalse);

      await store.setCompleted();
      await store.warmUp();
      expect(store.completedSync, isTrue);
    });

    test('resetForTesting clears completion flag', () async {
      final store = OnboardingStore.instance;
      await store.setCompleted();
      await store.resetForTesting();
      expect(store.completedSync, isFalse);
    });
  });
}
