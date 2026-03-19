import 'package:emlakmaster_mobile/features/auth/utils/auth_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('userFriendlyAuthError', () {
    test('wrong-password returns credential error message', () {
      final e = FirebaseAuthException(code: 'wrong-password', message: 'Wrong password');
      expect(userFriendlyAuthError(e), contains('E-posta veya şifre hatalı'));
      expect(userFriendlyAuthError(e), contains('Firebase Console'));
    });

    test('user-not-found returns credential error message', () {
      final e = FirebaseAuthException(code: 'user-not-found', message: 'No user');
      expect(userFriendlyAuthError(e), contains('E-posta veya şifre hatalı'));
    });

    test('invalid-credential returns credential error message', () {
      final e = FirebaseAuthException(code: 'invalid-credential', message: 'Invalid');
      expect(userFriendlyAuthError(e), contains('E-posta veya şifre hatalı'));
    });

    test('invalid-email returns email message', () {
      final e = FirebaseAuthException(code: 'invalid-email', message: 'Bad email');
      expect(userFriendlyAuthError(e), contains('Geçerli bir e-posta'));
    });

    test('user-disabled returns disabled message', () {
      final e = FirebaseAuthException(code: 'user-disabled', message: 'Disabled');
      expect(userFriendlyAuthError(e), contains('devre dışı'));
    });

    test('too-many-requests returns wait message', () {
      final e = FirebaseAuthException(code: 'too-many-requests', message: 'Throttled');
      expect(userFriendlyAuthError(e), contains('Çok fazla deneme'));
    });

    test('network-request-failed returns network message', () {
      final e = FirebaseAuthException(code: 'network-request-failed', message: 'Network error');
      expect(userFriendlyAuthError(e), contains('İnternet bağlantısı'));
    });

    test('operation-not-allowed returns Console hint', () {
      final e = FirebaseAuthException(code: 'operation-not-allowed', message: 'Not enabled');
      expect(userFriendlyAuthError(e), contains('E-posta/Şifre'));
      expect(userFriendlyAuthError(e), contains('Firebase Console'));
    });

    test('invalid-api-key returns config message', () {
      final e = FirebaseAuthException(code: 'invalid-api-key', message: 'Bad key');
      expect(userFriendlyAuthError(e), contains('Firebase yapılandırması'));
    });

    test('app-not-authorized returns config message', () {
      final e = FirebaseAuthException(code: 'app-not-authorized', message: 'Not authorized');
      expect(userFriendlyAuthError(e), contains('Firebase yapılandırması'));
    });

    test('unknown code returns generic message with code', () {
      final e = FirebaseAuthException(code: 'unknown-code', message: 'Whatever');
      final msg = userFriendlyAuthError(e);
      expect(msg, contains('unknown-code'));
      expect(msg, contains('Firebase Console'));
    });

    test('non-Firebase exception with wrong-password in string maps to credential message', () {
      final msg = userFriendlyAuthError(Exception('FirebaseAuthException: wrong-password'));
      expect(msg, contains('E-posta veya şifre hatalı'));
    });

    test('non-Firebase exception with invalid-email in string maps to email message', () {
      final msg = userFriendlyAuthError(Exception('invalid-email'));
      expect(msg, contains('Geçersiz e-posta'));
    });

    test('generic exception returns fallback message', () {
      final msg = userFriendlyAuthError(Exception('Something else'));
      expect(msg, contains('Giriş yapılamadı'));
      expect(msg, contains('E-posta/Şifre'));
    });
  });
}
