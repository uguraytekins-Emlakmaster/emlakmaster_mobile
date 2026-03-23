import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/data/user_repository.dart';

/// Tüm sağlayıcılar için idempotent profil senkronu (Firestore `users` doc **yoksa** yazı yok).
///
/// İlk girişte rol ataması [RoleSelectionPage] / `ensureUserDocProvider` akışında kalır;
/// burada sadece mevcut doc’a güvenli alan birleştirmesi yapılır.
abstract final class UserBootstrapOrchestrator {
  /// Başarılı Firebase oturumundan sonra: varsa `users/{uid}` ile e-posta/ad eşitle.
  static Future<void> afterSuccessfulAuth(User user) async {
    await UserRepository.mergeProfileIfDocExists(
      uid: user.uid,
      name: user.displayName,
      email: user.email,
    );
  }
}
