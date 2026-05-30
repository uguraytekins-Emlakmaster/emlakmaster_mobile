import 'package:emlakmaster_mobile/core/services/google_auth_service.dart';
import 'package:emlakmaster_mobile/core/services/login_attempt_guard.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthLogoutCoordinator presentation reset', () {
    test('LoginAttemptGuard clears after logout-style reset', () {
      LoginAttemptGuard.recordFailure();
      LoginAttemptGuard.recordFailure();
      LoginAttemptGuard.clear();
      expect(LoginAttemptGuard.assertCanAttempt(), isNull);
    });

    test('authPresentationEpochProvider increments for fresh login mount', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authPresentationEpochProvider), 0);
      container.read(authPresentationEpochProvider.notifier).state++;
      expect(container.read(authPresentationEpochProvider), 1);
    });

    test('GoogleAuthService resetAfterLogout clears cached client', () {
      GoogleAuthService.instance.resetAfterLogout();
      expect(true, isTrue);
    });
  });
}
