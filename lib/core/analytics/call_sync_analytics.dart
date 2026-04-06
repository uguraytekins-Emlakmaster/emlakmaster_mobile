import 'dart:async';

import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';

/// Çağrı senkron (Hive → Firestore) olayları — Firebase Analytics.
///
/// Olay yapısı (param anahtarları [AnalyticsEvents] içinde):
///
/// | Olay | Ne zaman | Parametreler |
/// |------|----------|----------------|
/// | `sync_success` | [markSynced], [linkFirestoreSession] | `sync_delay_ms`, `failure_rate` |
/// | `sync_failure` | [recordSyncFailure], ilk deneme | `retry_count`, `failure_rate`, `record_age_ms` |
/// | `sync_retry` | [recordSyncFailure], sonraki denemeler | `retry_count`, `failure_rate`, `record_age_ms` |
/// | `sync_permanent_failure` | [applyExpiredPermanentWindow] (parti) | `batch_count`, `avg_sync_delay_ms` |
///
/// [failure_rate] oturum içi tahmini: başarısız denemeler / (başarılar + başarısız denemeler).
/// `sync_delay_ms` tek örnek; kalıcı başarısızlıkta `avg_sync_delay_ms` partide ortalama.
/// Ağ gürültüsü: kalıcı pencere tek `sync_permanent_failure` ile toplu; diğerleri `unawaited`.
class CallSyncAnalytics {
  CallSyncAnalytics._();

  static int _sessionSuccesses = 0;
  static int _sessionFailedAttempts = 0;

  static double _failureRate() {
    final t = _sessionSuccesses + _sessionFailedAttempts;
    if (t == 0) return 0.0;
    return _sessionFailedAttempts / t;
  }

  static int _clampDelayMs(int ms) => ms.clamp(0, 86400000);

  /// [markSynced] / [CallLocalHiveStore.linkFirestoreSession] sonrası.
  static void logSyncSuccess({
    required int createdAtMs,
    required int syncedAtMs,
  }) {
    final delayMs = _clampDelayMs(syncedAtMs - createdAtMs);
    _sessionSuccesses++;
    final fr = _failureRate();
    unawaited(
      AnalyticsService.instance.logEvent(AnalyticsEvents.syncSuccess, {
        AnalyticsEvents.paramSyncDelayMs: delayMs,
        AnalyticsEvents.paramFailureRate: fr,
      }),
    );
  }

  /// [recordSyncFailure] — ilk başarısız deneme (önceki [syncAttemptCount] == 0).
  static void logSyncFailure({
    required int createdAtMs,
    required int nextRetryCount,
  }) {
    _sessionFailedAttempts++;
    final fr = _failureRate();
    unawaited(
      AnalyticsService.instance.logEvent(AnalyticsEvents.syncFailure, {
        AnalyticsEvents.paramRetryCount: nextRetryCount,
        AnalyticsEvents.paramFailureRate: fr,
        AnalyticsEvents.paramRecordAgeMs: _clampDelayMs(
          DateTime.now().millisecondsSinceEpoch - createdAtMs,
        ),
      }),
    );
  }

  /// [recordSyncFailure] — sonraki başarısız denemeler.
  static void logSyncRetry({
    required int createdAtMs,
    required int nextRetryCount,
  }) {
    _sessionFailedAttempts++;
    final fr = _failureRate();
    unawaited(
      AnalyticsService.instance.logEvent(AnalyticsEvents.syncRetry, {
        AnalyticsEvents.paramRetryCount: nextRetryCount,
        AnalyticsEvents.paramFailureRate: fr,
        AnalyticsEvents.paramRecordAgeMs: _clampDelayMs(
          DateTime.now().millisecondsSinceEpoch - createdAtMs,
        ),
      }),
    );
  }

  /// [applyExpiredPermanentWindow] — partide bir veya daha fazla kayıt.
  static void logPermanentFailureBatch({
    required int batchCount,
    required int avgSyncDelayMs,
  }) {
    if (batchCount <= 0) return;
    unawaited(
      AnalyticsService.instance.logEvent(AnalyticsEvents.syncPermanentFailure, {
        AnalyticsEvents.paramBatchCount: batchCount,
        AnalyticsEvents.paramAvgSyncDelayMs: _clampDelayMs(avgSyncDelayMs),
      }),
    );
  }

  /// Test veya çıkışta sıfırlamak için (isteğe bağlı).
  static void resetSessionCountersForTest() {
    _sessionSuccesses = 0;
    _sessionFailedAttempts = 0;
  }
}
