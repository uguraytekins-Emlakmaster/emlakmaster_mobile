/// Google Sign-In + Firebase Auth için **Web** OAuth 2.0 istemci kimliği.
///
/// Google Cloud Console → Credentials → "Web application" client ID ile aynı olmalı.
/// (iOS/Android istemci ID’leri burada kullanılmaz; idToken üretmek için Web gerekir.)
///
/// Bu değer `GoogleService-Info.plist` içindeki `CLIENT_ID` ile uyumlu tutuldu
/// (Firebase’de tek Web istemcisi kullanılıyorsa).
abstract final class GoogleOAuthConstants {
  /// google-services.json içindeki Web istemcisi (client_type 3) — Firebase ile uyumlu.
  static const String webClientId =
      '572835725773-m7hqe81ad42nnk5dv6k7gq0oup7pksj1.apps.googleusercontent.com';

  /// iOS: `GoogleService-Info.plist` → `CLIENT_ID` (Web ile farklı; idToken için ikisi birlikte gerekir).
  static const String iosClientId =
      '572835725773-8s71g3li2ful895gppeb6bvlbck09hkd.apps.googleusercontent.com';
}
