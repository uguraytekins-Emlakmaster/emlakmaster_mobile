import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingStore', () {
    test('instance is singleton', () {
      expect(OnboardingStore.instance, same(OnboardingStore.instance));
    });

    test('completedSync is bool (default false before warmUp)', () {
      expect(OnboardingStore.instance.completedSync, isA<bool>());
    });
  });
}
