import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/user_repository.dart';
import '../logging/app_logger.dart';
import 'auth_firestore_gate.dart';

/// Tüm sağlayıcılar için idempotent profil senkronu (Firestore `users` doc **yoksa** yazı yok).
///
/// İlk girişte rol ataması [RoleSelectionPage] / `ensureUserDocProvider` akışında kalır;
/// burada sadece mevcut doc’a güvenli alan birleştirmesi yapılır.
abstract final class UserBootstrapOrchestrator {
  /// Başarılı Firebase oturumundan sonra: jeton hazır → varsa `users/{uid}` ile
  /// e-posta/ad eşitle.
  ///
  /// KRİTİK (anayasa: error-resilience): Bu adım **en iyi çaba** (best-effort)
  /// ve **giriş akışını ASLA bloklamamalı**. Profil eşitlemesi navigasyon için
  /// gerekli değildir — router/shell `userDocStreamProvider`'ı bağımsız okur.
  /// Bu yüzden tüm iş kısa bir toplam timeout ile sınırlanır ve hatalar yutulur;
  /// böylece yavaş/dengesiz ağda giriş sonrası "sonsuz yükleniyor" oluşmaz.
  static Future<void> afterSuccessfulAuth(User user) async {
    try {
      await _bootstrap(user).timeout(const Duration(seconds: 6));
    } catch (e) {
      // Timeout / Firestore / token hatası giriş akışını durdurmamalı.
      if (kDebugMode) {
        AppLogger.w(
          'UserBootstrapOrchestrator.afterSuccessfulAuth best-effort skip: $e',
        );
      } else {
        AppLogger.state(
          '[startup] afterSuccessfulAuth best-effort skip (${e.runtimeType})',
        );
      }
      // Hata fırlatma: sign-in başarılı sayılır; profil senkronu arka planda
      // bir sonraki Firestore etkileşiminde yine denenebilir.
    }
  }

  static Future<void> _bootstrap(User user) async {
    await AuthFirestoreGate.ensureReadableUid(
      user.uid,
      forceRefresh: true,
      timeout: const Duration(seconds: 4),
    );
    await UserRepository.mergeProfileIfDocExists(
      uid: user.uid,
      name: user.displayName,
      email: user.email,
    );
  }
}
