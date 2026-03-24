import '../../features/auth/domain/auth_failure_kind.dart';
import '../../features/auth/domain/auth_result.dart';

/// Apple ile giriş — şu an **devre dışı** (ücretsiz Apple Developer hesabında
/// "Sign In with Apple" capability / profil uyumsuzluğu önlemi).
///
/// E-posta/şifre ve Google ile giriş kullanılabilir. Ücretli hesap ve capability
/// ile tekrar `sign_in_with_apple` entegrasyonu mümkün.
class AppleAuthService {
  AppleAuthService._();
  static final AppleAuthService instance = AppleAuthService._();

  /// Her zaman kapalı: UI bu akışı göstermez.
  Future<AuthResult> signInWithAppleForFirebase() async {
    return const AuthFailure(
      kind: AuthFailureKind.providerMisconfigured,
      userMessage:
          'Apple ile giriş şu an kullanılamıyor. E-posta veya Google ile devam edin.',
    );
  }
}
