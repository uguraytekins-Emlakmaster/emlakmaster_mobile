import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/domain/auth_result.dart';
import '../../features/auth/domain/auth_result_mapper.dart';
import '../config/google_oauth_constants.dart';
import '../logging/app_logger.dart';
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

  GoogleSignIn get _googleSignIn => _client ??= GoogleSignIn(
        scopes: const <String>['email', 'profile', 'openid'],
        serverClientId: GoogleOAuthConstants.webClientId,
        // iOS/macOS: Web serverClientId ile birlikte yerel CLIENT_ID şart; aksi halde idToken gelmeyebilir.
        clientId: !kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS)
            ? GoogleOAuthConstants.iosClientId
            : null,
      );

  /// Önce [signInSilently] (hızlı); idToken yoksa veya hesap yoksa tam akış.
  Future<UserCredential> signInWithGoogleForFirebase() async {
    GoogleSignInAccount? account;

    try {
      account = await _googleSignIn.signInSilently();
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
    }

    account = await _googleSignIn.signIn();
    if (account == null) {
      throw GoogleSignInUserCanceled();
    }

    // Bazı cihazlarda idToken birkaç ms gecikebiliyor.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var credential = await _buildCredential(account);
    credential ??= await _buildCredential(account);

    if (credential == null) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message:
            'Google oturum jetonu alınamadı. Firebase’de Google girişinin açık olduğundan ve '
            'Google Cloud’da Web OAuth istemcisinin tanımlı olduğundan emin olun. '
            'Android için SHA-1 parmak izini de ekleyin.',
      );
    }

    return _finishGoogleSignIn(await _signInWithGoogleCredential(credential));
  }

  /// [AuthResult] ile giriş — iptal ve hatalar tip güvenli.
  Future<AuthResult> signInWithGoogleTyped() async {
    try {
      final cred = await signInWithGoogleForFirebase().timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw FirebaseAuthException(
          code: 'timeout',
          message:
              'Google girişi zaman aşımına uğradı. Ağı kontrol edip tekrar deneyin.',
        ),
      );
      return AuthSuccess(cred);
    } on GoogleSignInUserCanceled {
      return const AuthCancelled();
    } on FirebaseAuthException catch (e) {
      return AuthResultMapper.fromFirebaseAuth(e);
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
      await _googleSignIn.signOut();
    } catch (e, st) {
      if (kDebugMode) AppLogger.d('GoogleAuthService: signOut', e, st);
    }
  }

  /// Test / özel senaryolar için (genelde gerekmez).
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e, st) {
      if (kDebugMode) AppLogger.d('GoogleAuthService: disconnect', e, st);
    }
  }
}
