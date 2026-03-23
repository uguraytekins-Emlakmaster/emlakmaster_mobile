import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../features/auth/domain/auth_failure_kind.dart';
import '../../features/auth/domain/auth_result.dart';
import '../../features/auth/domain/auth_result_mapper.dart';
import '../config/auth_provider_config.dart';
import '../logging/app_logger.dart';
import 'user_bootstrap_orchestrator.dart';

/// Sign in with Apple → Firebase `OAuthProvider('apple.com')` (nonce ile).
///
/// UI bu sınıfı doğrudan kullanır; widget içinde Firebase çağrısı yok.
class AppleAuthService {
  AppleAuthService._();
  static final AppleAuthService instance = AppleAuthService._();

  /// Apple oturumu + Firebase. İptal → [AuthCancelled], hata → [AuthFailure].
  Future<AuthResult> signInWithAppleForFirebase() async {
    if (!AuthProviderConfig.isAppleSignInSupported) {
      return const AuthFailure(
        kind: AuthFailureKind.providerMisconfigured,
        userMessage: 'Apple ile giriş bu cihazda kullanılamıyor.',
      );
    }

    final rawNonce = _generateNonce();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        return const AuthFailure(
          kind: AuthFailureKind.invalidCredential,
          userMessage: 'Apple oturum belirteci alınamadı. Tekrar deneyin.',
        );
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
      );

      final cred =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      await _applyAppleFullNameIfNeeded(cred.user, appleCredential);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserBootstrapOrchestrator.afterSuccessfulAuth(user);
      }

      return AuthSuccess(cred);
    } on SignInWithAppleAuthorizationException catch (e, st) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AuthCancelled();
      }
      if (kDebugMode) {
        AppLogger.d('AppleAuthService: authorization failed', e, st);
      }
      return AuthFailure(
        kind: AuthFailureKind.unknownError,
        userMessage: 'Apple ile giriş tamamlanamadı. Tekrar deneyin.',
        debugDetail: e.toString(),
        cause: e,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResultMapper.fromFirebaseAuth(e);
    } catch (e, st) {
      if (kDebugMode) AppLogger.d('AppleAuthService: signIn', e, st);
      return AuthResultMapper.fromUnknown(e);
    }
  }

  static Future<void> _applyAppleFullNameIfNeeded(
    User? user,
    AuthorizationCredentialAppleID appleCredential,
  ) async {
    if (user == null) return;
    final given = appleCredential.givenName;
    final family = appleCredential.familyName;
    final parts = <String>[];
    if (given != null && given.isNotEmpty) parts.add(given);
    if (family != null && family.isNotEmpty) parts.add(family);
    final dn = parts.join(' ');
    if (dn.isEmpty) return;
    if (user.displayName != null && user.displayName!.isNotEmpty) return;
    try {
      await user.updateDisplayName(dn);
      await user.reload();
    } catch (e, st) {
      if (kDebugMode) AppLogger.d('AppleAuthService: updateDisplayName', e, st);
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
