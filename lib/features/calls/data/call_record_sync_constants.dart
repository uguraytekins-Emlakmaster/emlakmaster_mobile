/// Offline çağrı senkronu sabitleri.
abstract final class CallRecordSyncConstants {
  /// 24 saat içinde senkron olmayan kayıt kalıcı başarısız sayılır.
  static const int maxRetryWindowMs = 24 * 60 * 60 * 1000;

  /// Senkron takılırsa otomatik kilit açma (ms).
  static const int staleSyncingLockMs = 2 * 60 * 1000;

  /// Firestore’da aynı çağrı sayılması için ±2 dakika pencere.
  static const int dedupeWindowMs = 2 * 60 * 1000;
}
