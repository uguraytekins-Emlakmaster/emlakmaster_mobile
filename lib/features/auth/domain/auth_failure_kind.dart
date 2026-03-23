/// Kimlik doğrulama hatalarının sabit kategorileri — UI ve loglama için.
enum AuthFailureKind {
  /// Ağ / zaman aşımı
  networkError,

  /// OAuth istemcisi, Firebase provider veya Apple capability eksik
  providerMisconfigured,

  /// Kullanıcı iptal (iptal analytics’e yazılmaz; throttling tetiklenmez)
  userCancelled,

  /// idToken / credential geçersiz
  invalidCredential,

  /// Aynı e-posta farklı sağlayıcı
  accountConflict,

  /// Bilinen olmayan veya sarmalanmamış hata
  unknownError,
}
