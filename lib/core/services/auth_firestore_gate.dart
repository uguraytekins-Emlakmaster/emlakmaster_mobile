import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Firestore okumaları önce oturum jetonunun hazır olmasını bekler (çıkış → tekrar giriş yarışı).
abstract final class AuthFirestoreGate {
  static Future<void> ensureReadableUid(
    String uid, {
    Duration timeout = const Duration(seconds: 8),
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty || Firebase.apps.isEmpty) return;

    final deadline = DateTime.now().add(timeout);
    Object? lastError;

    while (DateTime.now().isBefore(deadline)) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        try {
          await user.getIdToken(forceRefresh);
          return;
        } catch (e, st) {
          lastError = e;
          if (kDebugMode) {
            AppLogger.d('AuthFirestoreGate.ensureReadableUid token', e, st);
          }
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (kDebugMode) {
      AppLogger.w(
        'AuthFirestoreGate: timeout uid=$uid live=${FirebaseAuth.instance.currentUser?.uid} err=$lastError',
      );
    }
  }

  /// Oturum kapandıktan sonra canlı Firebase kullanıcısının null olmasını bekler.
  static Future<void> waitUntilSignedOut({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (Firebase.apps.isEmpty) return;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (FirebaseAuth.instance.currentUser == null) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  static bool liveUidMatches(String uid) {
    if (uid.isEmpty) return false;
    return FirebaseAuth.instance.currentUser?.uid == uid;
  }
}
