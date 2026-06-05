import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/features/auth/utils/auth_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizations(const Locale('tr'));

  group('userFriendlyAuthError', () {
    test('wrong-password returns credential error message', () {
      final e = FirebaseAuthException(code: 'wrong-password', message: 'Wrong password');
      expect(userFriendlyAuthError(l10n, e), contains('E-posta veya şifre hatalı'));
    });

    test('user-not-found returns credential error message', () {
      final e = FirebaseAuthException(code: 'user-not-found', message: 'No user');
      expect(userFriendlyAuthError(l10n, e), contains('E-posta veya şifre hatalı'));
    });

    test('invalid-credential returns credential error message', () {
      final e = FirebaseAuthException(code: 'invalid-credential', message: 'Invalid');
      expect(userFriendlyAuthError(l10n, e), contains('E-posta veya şifre hatalı'));
    });

    test('invalid-email returns email message', () {
      final e = FirebaseAuthException(code: 'invalid-email', message: 'Bad email');
      expect(userFriendlyAuthError(l10n, e), contains('Geçerli bir e-posta'));
    });

    test('user-disabled returns disabled message', () {
      final e = FirebaseAuthException(code: 'user-disabled', message: 'Disabled');
      expect(userFriendlyAuthError(l10n, e), contains('devre dışı'));
    });

    test('too-many-requests returns wait message', () {
      final e = FirebaseAuthException(code: 'too-many-requests', message: 'Throttled');
      expect(userFriendlyAuthError(l10n, e), contains('Çok fazla deneme'));
    });

    test('network-request-failed returns network message', () {
      final e = FirebaseAuthException(code: 'network-request-failed', message: 'Network error');
      expect(userFriendlyAuthError(l10n, e), contains('İnternet bağlantısı'));
    });

    test('operation-not-allowed returns disabled message', () {
      final e = FirebaseAuthException(code: 'operation-not-allowed', message: 'Not enabled');
      expect(userFriendlyAuthError(l10n, e), contains('E-posta/Şifre'));
    });

    test('invalid-api-key returns config message', () {
      final e = FirebaseAuthException(code: 'invalid-api-key', message: 'Bad key');
      expect(userFriendlyAuthError(l10n, e), contains('Firebase yapılandırması'));
    });

    test('app-not-authorized returns config message', () {
      final e = FirebaseAuthException(code: 'app-not-authorized', message: 'Not authorized');
      expect(userFriendlyAuthError(l10n, e), contains('Firebase yapılandırması'));
    });

    test('unknown code returns generic message with code', () {
      final e = FirebaseAuthException(code: 'unknown-code', message: 'Whatever');
      final msg = userFriendlyAuthError(l10n, e);
      expect(msg, contains('unknown-code'));
    });

    test('non-Firebase exception with wrong-password in string maps to credential message', () {
      final msg = userFriendlyAuthError(l10n, Exception('FirebaseAuthException: wrong-password'));
      expect(msg, contains('E-posta veya şifre hatalı'));
    });

    test('non-Firebase exception with invalid-email in string maps to email message', () {
      final msg = userFriendlyAuthError(l10n, Exception('invalid-email'));
      expect(msg, contains('Geçersiz e-posta'));
    });

    test('generic exception returns fallback message', () {
      final msg = userFriendlyAuthError(l10n, Exception('Something else'));
      expect(msg, contains('Giriş yapılamadı'));
      expect(msg, contains('kontrol edin'));
    });
  });
}
