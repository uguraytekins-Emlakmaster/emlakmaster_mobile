import 'package:emlakmaster_mobile/features/auth/domain/auth_failure_kind.dart';
import 'package:emlakmaster_mobile/features/auth/domain/auth_result.dart';
import 'package:emlakmaster_mobile/features/auth/domain/auth_result_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthResultMapper.fromFirebaseAuth', () {
    test('maps invalid-credential to invalidCredential', () {
      expect(
        AuthResultMapper.fromFirebaseAuth(
          FirebaseAuthException(code: 'invalid-credential'),
        ),
        isA<AuthFailure>().having((f) => f.kind, 'kind', AuthFailureKind.invalidCredential),
      );
    });

    test('maps account-exists-with-different-credential to accountConflict', () {
      expect(
        AuthResultMapper.fromFirebaseAuth(
          FirebaseAuthException(code: 'account-exists-with-different-credential'),
        ),
        isA<AuthFailure>().having((f) => f.kind, 'kind', AuthFailureKind.accountConflict),
      );
    });

    test('maps timeout to networkError', () {
      expect(
        AuthResultMapper.fromFirebaseAuth(
          FirebaseAuthException(code: 'timeout', message: 'timeout'),
        ),
        isA<AuthFailure>().having((f) => f.kind, 'kind', AuthFailureKind.networkError),
      );
    });

    test('maps operation-not-allowed to providerMisconfigured', () {
      expect(
        AuthResultMapper.fromFirebaseAuth(
          FirebaseAuthException(code: 'operation-not-allowed'),
        ),
        isA<AuthFailure>().having((f) => f.kind, 'kind', AuthFailureKind.providerMisconfigured),
      );
    });
  });
}
