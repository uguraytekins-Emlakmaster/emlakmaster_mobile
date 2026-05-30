import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/domain/auth_result.dart';
import '../../features/auth/domain/auth_result_mapper.dart';
import '../config/google_oauth_constants.dart';
import '../logging/app_logger.dart';
import 'firebase_core_bootstrap.dart';
import 'user_bootstrap_orchestrator.dart';

/// Kullanıcı hesap seçiciyi kapattığında (iptal).
class GoogleSignInUserCanceled implements Exception {
  @override
  String toString() => 'GoogleSignInUserCanceled';
}

/// Tek [GoogleSignIn] örneği: sessile giriş + Firebase credential.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  GoogleSignIn? _client;

  bool get _isMacOs =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  bool get _isAppleNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  GoogleSignIn get _googleSignIn => _client ??= _createClient();

  GoogleSignIn _createClient() => GoogleSignIn(
        scopes: const <String>['email', 'profile', 'openid'],
        serverClientId: GoogleOAuthConstants.webClientId,
        clientId: _isAppleNative ? GoogleOAuthConstants.iosClientId : null,
        forceCodeForRefreshToken: _isMacOs,
      );

  void _resetClient() {
    _client = null;
  }

  /// Önce [signInSilently] (hızlı); idToken yoksa veya hesap yoksa tam akış.
  Future<UserCredential> signInWithGoogleForFirebase() async {
    await FirebaseCoreBootstrap.instance.ensureReady();
    GoogleSignInAccount? account;

    // macOS: sessiz oturum keychain'de takılabiliyor — doğrudan interaktif akış.
    if (!_isMacOs) {
      try {
        account = await _googleSignIn.signInSilently().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
      } on PlatformException catch (e, st) {
        if (kDebugMode) {
          AppLogger.d('GoogleAuthService: signInSilently ${e.code}', e, st);
        }
      } catch (e, st) {
        if (kDebugMode) AppLogger.d('GoogleAuthService: signInSilently', e, st);
      }

      if (account != null) {
        final credential = await _buildCredential(account);
        if (credential != null) {
          return _finishGoogleSignIn(
            await _signInWithGoogleCredential(credential),
          );
        }
        if (kDebugMode) {
          AppLogger.d(
            'GoogleAuthService: silent session without idToken — clearing before interactive sign-in',
          );
        }
        await _clearGoogleSession();
        account = null;
      }
    } else {
      if (_client != null) {
        await _clearGoogleSession();
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }

    account = await _interactiveSignIn();
    if (account == null) {
      throw GoogleSignInUserCanceled();
    }

    final credential = await _buildCredentialWithRetry(account);
    if (credential == null) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message:
            'Google oturum jetonu alınamadı. Firebase’de Google girişinin açık olduğundan ve '
            'Google Cloud’da Web OAuth istemcisinin tanımlı olduğundan emin olun. '
            'macOS’ta uygulamayı tamamen kapatıp yeniden derleyin (hot reload yetmez).',
      );
    }

    return _finishGoogleSignIn(await _signInWithGoogleCredential(credential));
  }

  Future<GoogleSignInAccount?> _interactiveSignIn() async {
    try {
      return await _googleSignIn.signIn().timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw PlatformException(
          code: 'sign_in_failed',
          message:
              'Google oturum penceresi açılamadı. Dock’ta Safari/Chrome penceresine bakın veya uygulamayı öne getirip tekrar deneyin.',
        ),
      );
    } on PlatformException catch (e, st) {
      if (kDebugMode) {
        AppLogger.d('GoogleAuthService: signIn ${e.code}', e, st);
      }
      rethrow;
    }
  }

  Future<void> _clearGoogleSession() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.signOut().timeout(const Duration(seconds: 3));
    } catch (e, st) {
      if (kDebugMode) {
        AppLogger.d('GoogleAuthService: signOut before interactive', e, st);
      }
    }
    _resetClient();
    // disconnect() macOS'ta ağ/keychain yüzünden takılabiliyor — kullanma.
  }

  Future<OAuthCredential?> _buildCredentialWithRetry(
    GoogleSignInAccount account,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final credential = await _buildCredential(account);
      if (credential != null) return credential;
      await Future<void>.delayed(Duration(milliseconds: 150 * (attempt + 1)));
    }
    return null;
  }

  /// [AuthResult] ile giriş — iptal ve hatalar tip güvenli.
  Future<AuthResult> signInWithGoogleTyped() async {
    try {
      final cred = await signInWithGoogleForFirebase().timeout(
        const Duration(seconds: 130),
        onTimeout: () => throw FirebaseAuthException(
          code: 'timeout',
          message:
              'Google girişi zaman aşımına uğradı. Ağı kontrol edip tekrar deneyin.',
        ),
      );
      return AuthSuccess(cred);
    } on GoogleSignInUserCanceled {
      return const AuthCancelled();
    } on PlatformException catch (e) {
      return AuthResultMapper.fromPlatformException(e);
    } on FirebaseAuthException catch (e) {
      return AuthResultMapper.fromFirebaseAuth(e);
    } on FirebaseException catch (e) {
      return AuthResultMapper.fromFirebaseCore(e);
    } catch (e) {
      return AuthResultMapper.fromUnknown(e);
    }
  }

  Future<UserCredential> _finishGoogleSignIn(UserCredential cred) async {
    final u = cred.user;
    if (u != null) {
      await UserBootstrapOrchestrator.afterSuccessfulAuth(u);
    }
    return cred;
  }

  Future<UserCredential> _signInWithGoogleCredential(OAuthCredential credential) async {
    try {
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        await signOut();
      }
      rethrow;
    }
  }

  Future<OAuthCredential?> _buildCredential(GoogleSignInAccount account) async {
    final GoogleSignInAuthentication auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      return null;
    }
    return GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: idToken,
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 3));
    } catch (e, st) {
      if (kDebugMode) AppLogger.d('GoogleAuthService: signOut', e, st);
    }
    _resetClient();
  }

  /// Test / özel senaryolar için (genelde gerekmez).
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect().timeout(const Duration(seconds: 5));
    } catch (e, st) {
      if (kDebugMode) AppLogger.d('GoogleAuthService: disconnect', e, st);
    }
    _resetClient();
  }
}
