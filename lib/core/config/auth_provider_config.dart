import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'google_oauth_constants.dart';

/// Kimlik doğrulama ile ilgili tek kaynak: hangi sağlayıcılar bu derlemede anlamlı.
abstract final class AuthProviderConfig {
  /// Google Web / iOS istemci kimlikleri — [GoogleOAuthConstants].
  static String get googleWebClientId => GoogleOAuthConstants.webClientId;

  static String get googleIosClientId => GoogleOAuthConstants.iosClientId;

  /// Sign in with Apple: iOS ve macOS yerel akışı (web/Android’de kullanılmaz).
  static bool get isAppleSignInSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}
