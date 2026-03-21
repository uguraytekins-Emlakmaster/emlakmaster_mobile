import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Uzun oturumlar: ön planda yeniden gelince token ve kullanıcı durumu tazelenir
/// (devre dışı hesap, Firestore kuralları ile uyumlu güncel JWT).
class AuthSessionCoordinator {
  AuthSessionCoordinator._();
  static DateTime? _lastResumeRefresh;

  /// Uygulama öne gelince (soğuk değil, throttled).
  static Future<void> refreshOnAppResume() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    if (_lastResumeRefresh != null &&
        now.difference(_lastResumeRefresh!) < const Duration(minutes: 3)) {
      return;
    }
    _lastResumeRefresh = now;
    try {
      await user.reload();
      final after = FirebaseAuth.instance.currentUser;
      if (after == null) {
        await FirebaseAuth.instance.signOut();
        return;
      }
      await after.getIdToken(true);
    } catch (e, st) {
      if (kDebugMode) AppLogger.d('AuthSessionCoordinator.refreshOnAppResume', e, st);
    }
  }
}
