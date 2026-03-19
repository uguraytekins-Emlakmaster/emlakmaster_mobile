import 'package:emlakmaster_mobile/core/services/login_attempt_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LoginAttemptGuard.clear());

  test('assertCanAttempt allows initially', () {
    expect(LoginAttemptGuard.assertCanAttempt(), isNull);
  });

  test('after many failures blocks temporarily', () {
    for (var i = 0; i < 12; i++) {
      LoginAttemptGuard.recordFailure();
    }
    expect(LoginAttemptGuard.assertCanAttempt(), isNotNull);
  });

  test('clear resets guard', () {
    for (var i = 0; i < 12; i++) {
      LoginAttemptGuard.recordFailure();
    }
    LoginAttemptGuard.clear();
    expect(LoginAttemptGuard.assertCanAttempt(), isNull);
  });
}
