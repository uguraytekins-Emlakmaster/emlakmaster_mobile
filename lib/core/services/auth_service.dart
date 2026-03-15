import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Gerçek kullanıcı girişi: email/şifre, logout, session.
class AuthService {
  AuthService._();

  static AuthService get instance => _instance;
  static final AuthService _instance = AuthService._();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();

  /// Email/şifre ile giriş.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (kDebugMode) AppLogger.d('AuthService: signIn success ${currentUser?.uid}');
  }

  /// Çıkış.
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (kDebugMode) AppLogger.d('AuthService: signOut');
  }

  /// Session restore: authStateChanges stream ile otomatik; ek işlem gerekmez.
}
