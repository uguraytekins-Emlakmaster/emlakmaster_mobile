import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'facebook_auth_service.dart';
import 'google_auth_service.dart';
import '../logging/app_logger.dart';

/// Gerçek kullanıcı girişi: email/şifre, logout, session.
class AuthService {
  AuthService._();

  static AuthService get instance => _instance;
  static final AuthService _instance = AuthService._();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  /// Email/şifre ile giriş.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (kDebugMode) {
      AppLogger.d('AuthService: signIn success ${currentUser?.uid}');
    }
  }

  /// Yeni hesap: Firebase Auth + isteğe bağlı görünen ad (rol seçimi router ile aynı akışta).
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty && cred.user != null) {
      await cred.user!.updateDisplayName(name);
      await cred.user!.reload();
    }
    if (kDebugMode) {
      AppLogger.d('AuthService: register success ${cred.user?.uid}');
    }
    return cred;
  }

  /// Şifre sıfırlama e-postası gönderir (Firebase Auth).
  /// E-posta geçerli bir hesaba aitse kullanıcı bağlantı alır.
  /// Firebase Console'da Authentication > Sign-in method içinde "E-posta/Şifre" etkin olmalıdır.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final trimmed = email.trim();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmed);
      if (kDebugMode) {
        AppLogger.d('AuthService: password reset email sent to $trimmed');
      }
    } catch (e, st) {
      if (kDebugMode) {
        AppLogger.d('AuthService: sendPasswordResetEmail failed', e, st);
        if (e is FirebaseAuthException) {
          AppLogger.d(
              'AuthService: Firebase code=${e.code} message=${e.message}');
        }
      }
      rethrow;
    }
  }

  /// Çıkış: Firebase + sosyal oturumlar (sonraki girişte hesap seçici açılır).
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleAuthService.instance.signOut();
    } catch (_) {/* Google oturumu yoksa veya ağ yoksa yine de çıkış tamam */}
    try {
      await FacebookAuthService.instance.signOut();
    } catch (_) {/* Facebook oturumu yoksa veya ağ yoksa yine de çıkış tamam */}
    if (kDebugMode) AppLogger.d('AuthService: signOut');
  }

  /// Session restore: authStateChanges stream ile otomatik; ek işlem gerekmez.
}
