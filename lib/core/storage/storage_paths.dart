/// Firebase Storage object path helpers — tek doğruluk kaynağı (kurallarla uyumlu).
abstract final class StoragePaths {
  /// `users/{uid}/avatar/{fileName}` — örn. avatar_256.jpg
  static String userAvatar(String uid, {String fileName = 'avatar_256.jpg'}) {
    return 'users/$uid/avatar/$fileName';
  }

  /// `offices/{officeId}/logo/{fileName}`
  static String officeLogo(String officeId, String fileName) {
    return 'offices/$officeId/logo/$fileName';
  }

  /// `offices/{officeId}/imports/{sessionId}/{fileName}` — sessionId istemci üretir (izlenebilirlik).
  static String officeImport(String officeId, String sessionId, String fileName) {
    return 'offices/$officeId/imports/$sessionId/$fileName';
  }

  /// Eski global vitrin logosu (app_settings / yönetici) — geriye dönük.
  static String listingDisplayLogo(String fileName) {
    return 'listing_display/$fileName';
  }
}
