import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'auth_failure_kind.dart';
import 'auth_result.dart';

/// Firebase / platform hatalarını [AuthFailure]'a çevirir.
abstract final class AuthResultMapper {
  static AuthFailure fromFirebaseAuth(FirebaseAuthException e, {String? context}) {
    final detail = '${e.code}${e.message != null && e.message!.isNotEmpty ? ': ${e.message}' : ''}';
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
      case 'invalid-credential':
        return AuthFailure(
          kind: AuthFailureKind.invalidCredential,
          userMessage: e.message ?? 'Giriş bilgileri doğrulanamadı.',
          debugDetail: detail,
          cause: e,
        );
      case 'account-exists-with-different-credential':
        return AuthFailure(
          kind: AuthFailureKind.accountConflict,
          userMessage:
              'Bu e-posta başka bir giriş yöntemiyle kayıtlı. Aynı yöntemi kullanın veya destek alın.',
          debugDetail: detail,
          cause: e,
        );
      case 'network-request-failed':
        return AuthFailure(
          kind: AuthFailureKind.networkError,
          userMessage: 'İnternet bağlantısı yok veya zayıf.',
          debugDetail: detail,
          cause: e,
        );
      case 'operation-not-allowed':
        return AuthFailure(
          kind: AuthFailureKind.providerMisconfigured,
          userMessage: 'Bu giriş yöntemi şu an etkin değil. Yönetici ile iletişime geçin.',
          debugDetail: detail,
          cause: e,
        );
      case 'too-many-requests':
        return AuthFailure(
          kind: AuthFailureKind.networkError,
          userMessage: 'Çok fazla deneme. Lütfen kısa süre sonra tekrar deneyin.',
          debugDetail: detail,
          cause: e,
        );
      case 'timeout':
        return AuthFailure(
          kind: AuthFailureKind.networkError,
          userMessage: e.message ?? 'İşlem zaman aşımına uğradı. Ağı kontrol edip tekrar deneyin.',
          debugDetail: detail,
          cause: e,
        );
      default:
        return AuthFailure(
          kind: AuthFailureKind.unknownError,
          userMessage: context ?? 'Giriş yapılamadı. Tekrar deneyin.',
          debugDetail: detail,
          cause: e,
        );
    }
  }

  static AuthFailure fromUnknown(Object e, {String? context}) {
    final s = e.toString();
    if (e is PlatformException) {
      final c = e.code.toLowerCase();
      final m = '${e.message}'.toLowerCase();
      if (c.contains('cancel') || m.contains('cancel')) {
        return AuthFailure(
          kind: AuthFailureKind.userCancelled,
          userMessage: '',
          debugDetail: e.code,
          cause: e,
        );
      }
    }
    return AuthFailure(
      kind: AuthFailureKind.unknownError,
      userMessage: context ?? 'Beklenmeyen bir hata oluştu.',
      debugDetail: s.length > 200 ? '${s.substring(0, 200)}…' : s,
      cause: e,
    );
  }
}
