import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'facebook_auth_service.dart';
import 'firebase_core_bootstrap.dart';
import 'google_auth_service.dart';
import 'logout_flow_tracer.dart';
import 'user_bootstrap_orchestrator.dart';
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
    await FirebaseCoreBootstrap.instance.ensureReady();
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final u = currentUser;
    if (u != null) {
      await UserBootstrapOrchestrator.afterSuccessfulAuth(u);
    }
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
    await FirebaseCoreBootstrap.instance.ensureReady();
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty && cred.user != null) {
      await cred.user!.updateDisplayName(name);
      await cred.user!.reload();
    }
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      await UserBootstrapOrchestrator.afterSuccessfulAuth(u);
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
      await FirebaseCoreBootstrap.instance.ensureReady();
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

  bool _signOutInProgress = false;

  /// Çıkış: Firebase + sosyal oturumlar (sonraki girişte hesap seçici açılır).
  Future<void> signOut() async {
    if (_signOutInProgress) return;
    _signOutInProgress = true;
    try {
      LogoutFlowTracer.step('LOGOUT_FLOW', 'FirebaseCoreBootstrap.ensureReady');
      if (Firebase.apps.isEmpty) {
        await LogoutFlowTracer.watch(
          'firebase_bootstrap',
          FirebaseCoreBootstrap.instance.ensureReady(),
        );
      }
      LogoutFlowTracer.step('LOGOUT_FLOW', 'FirebaseAuth.signOut start');
      await LogoutFlowTracer.watch(
        'firebase_auth_sign_out',
        FirebaseAuth.instance.signOut(),
      );
      LogoutFlowTracer.step('LOGOUT_FLOW', 'FirebaseAuth.signOut end');
      unawaited(_signOutSocialSessions());
      if (kDebugMode) AppLogger.d('AuthService: signOut');
    } finally {
      _signOutInProgress = false;
    }
  }

  /// Geçerli oturumun sağlayıcı kimlikleri (ör. 'password', 'google.com').
  List<String> get providerIds =>
      currentUser?.providerData.map((p) => p.providerId).toList() ??
      const <String>[];

  /// E-posta/şifre ile açılmış bir hesap mı (şifre değiştirme bunu gerektirir).
  bool get isPasswordProvider => providerIds.contains('password');

  /// Hassas işlemler (şifre/e-posta değiştirme, hesap silme) öncesi yeniden
  /// kimlik doğrulama. Firebase, son girişten uzun süre geçtiyse bunu ister.
  Future<void> reauthenticateWithPassword(String currentPassword) async {
    final user = currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Oturum bulunamadı.',
      );
    }
    final cred =
        EmailAuthProvider.credential(email: email, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
  }

  /// Yeni şifre belirler. Çağrıdan önce [reauthenticateWithPassword] gerekebilir.
  Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
          code: 'no-current-user', message: 'Oturum bulunamadı.');
    }
    await user.updatePassword(newPassword);
  }

  /// Yeni e-postaya doğrulama bağlantısı gönderir; kullanıcı onaylayınca e-posta
  /// güncellenir (Firebase `verifyBeforeUpdateEmail`). Reauth gerekebilir.
  Future<void> sendEmailUpdateVerification(String newEmail) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
          code: 'no-current-user', message: 'Oturum bulunamadı.');
    }
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  /// Mevcut kullanıcı için şifre sıfırlama e-postası gönderir.
  Future<void> sendPasswordResetForCurrentUser() async {
    final email = currentUser?.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
          code: 'no-email', message: 'Hesaba bağlı e-posta yok.');
    }
    await sendPasswordResetEmail(email: email);
  }

  /// Firebase Auth hesabını siler. Reauth gerekebilir (`requires-recent-login`).
  /// Firestore kullanıcı verisi temizliği çağıran tarafça yapılır.
  Future<void> deleteCurrentUser() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
          code: 'no-current-user', message: 'Oturum bulunamadı.');
    }
    await user.delete();
    if (kDebugMode) AppLogger.d('AuthService: account deleted');
  }

  Future<void> _signOutSocialSessions() async {
    LogoutFlowTracer.step('LOGOUT_FLOW', 'social signOut start');
    try {
      await GoogleAuthService.instance.signOut().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          LogoutFlowTracer.step('LOGOUT_FLOW', 'Google signOut timeout');
        },
      );
    } catch (_) {}
    try {
      await FacebookAuthService.instance.signOut().timeout(
        const Duration(seconds: 1),
      );
    } catch (_) {}
    LogoutFlowTracer.step('LOGOUT_FLOW', 'social signOut end');
  }

  /// Session restore: authStateChanges stream ile otomatik; ek işlem gerekmez.
}
