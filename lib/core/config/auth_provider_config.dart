import 'google_oauth_constants.dart';

/// Kimlik doğrulama ile ilgili tek kaynak: hangi sağlayıcılar bu derlemede anlamlı.
abstract final class AuthProviderConfig {
  /// Google Web / iOS istemci kimlikleri — [GoogleOAuthConstants].
  static String get googleWebClientId => GoogleOAuthConstants.webClientId;

  static String get googleIosClientId => GoogleOAuthConstants.iosClientId;

  /// Sign in with Apple: **kapalı** (ücretsiz Apple hesabı + provisioning).
  /// Ücretli program + capability ile tekrar açılabilir.
  static bool get isAppleSignInSupported => false;
}
