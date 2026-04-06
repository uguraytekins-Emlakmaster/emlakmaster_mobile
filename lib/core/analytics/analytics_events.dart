/// Firebase Analytics özel olay adları — tek kaynak (snake_case, 40 karakter önerisi).
///
/// Standart giriş/ekran: [AnalyticsService] içinde `logLogin` / `logSignUp` / `logScreenView`.
/// Burada yalnızca `logEvent` ile gönderilen isimler tutulur.
abstract final class AnalyticsEvents {
  AnalyticsEvents._();

  // —— Ekran adları (GoRouter `name` ile çoğunlukla gelir; manuel kullanım nadirdir) ——
  static const String screenConsultantDashboard = 'consultant_dashboard';

  // —— İlan ——
  static const String listingView = 'listing_view';
  static const String settingsChange = 'settings_change';

  // —— Çağrılar / danışman ——
  static const String callsExportCsv = 'calls_export_csv';
  static const String callsBulkSms = 'calls_bulk_sms';
  static const String callsBulkWhatsappStart = 'calls_bulk_whatsapp_start';
  static const String callsDeviceSyncResult = 'calls_device_sync_result';
  static const String callsDevicePermissionDenied =
      'calls_device_permission_denied';
  static const String callsDeviceSyncSuccess = 'calls_device_sync_success';
  static const String callsDeviceSyncError = 'calls_device_sync_error';
  static const String magicCallTap = 'magic_call_tap';
  static const String consultantCallsTap = 'consultant_calls_tap';
  static const String limitReachedCall = 'limit_reached_call';
  static const String limitReachedAi = 'limit_reached_ai';
  static const String upgradeClicked = 'upgrade_clicked';
  static const String upgradeConverted = 'upgrade_converted';

  // —— Yerel çağrı kaydı → Firestore senkron (Hive) ——
  static const String syncSuccess = 'sync_success';
  static const String syncFailure = 'sync_failure';
  static const String syncRetry = 'sync_retry';
  static const String syncPermanentFailure = 'sync_permanent_failure';

  // Param anahtarları (tutarlılık)
  static const String paramCount = 'count';
  static const String paramListingId = 'listing_id';
  static const String paramSource = 'source';
  static const String paramSetting = 'setting';
  static const String paramError = 'error';
  static const String paramResult = 'result';
  static const String paramFeature = 'feature';
  static const String paramPermanently = 'permanently';
  static const String paramSyncedCount = 'synced_count';

  /// Başarı: [LocalCallRecord.createdAt] → senkron tamamlandığı an (ms).
  /// Sunucuda ortalama: BigQuery / GA4 raporları.
  static const String paramSyncDelayMs = 'sync_delay_ms';

  /// Başarısız deneme anında kaydın yaşı (oluşturulma → şimdi, ms).
  static const String paramRecordAgeMs = 'record_age_ms';

  /// Aynı oturumda tahmini başarısızlık oranı (0.0–1.0).
  static const String paramFailureRate = 'failure_rate';

  /// [recordSyncFailure] sonrası yeni deneme sayacı.
  static const String paramRetryCount = 'retry_count';

  /// [applyExpiredPermanentWindow] tek partide etkilenen kayıt sayısı.
  static const String paramBatchCount = 'batch_count';

  /// Parti içi ortalama gecikme (kalıcı başarısızlık anına kadar).
  static const String paramAvgSyncDelayMs = 'avg_sync_delay_ms';
}
