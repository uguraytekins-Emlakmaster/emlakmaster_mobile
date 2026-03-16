/// Rainbow CRM / EmlakMaster – uygulama sabitleri. Magic string kullanmayın.
abstract final class AppConstants {
  AppConstants._();

  static const String appName = 'Rainbow CRM';
  static const String appShortName = 'EmlakMaster';

  /// Firestore koleksiyon adları (spec ile uyumlu)
  static const String colUsers = 'users';
  static const String colRoles = 'roles';
  static const String colPermissions = 'permissions';
  static const String colAgents = 'agents';
  static const String colCustomers = 'customers';
  static const String colLeads = 'leads';
  static const String colCalls = 'calls';
  static const String colCallEvents = 'call_events';
  static const String colCallSummaries = 'call_summaries';
  static const String colCallOutcomes = 'call_outcomes';
  static const String colListings = 'listings';
  static const String colListingMetrics = 'listing_metrics';
  static const String colOffers = 'offers';
  static const String colVisits = 'visits';
  static const String colTasks = 'tasks';
  static const String colNotifications = 'notifications';
  static const String colPipelineItems = 'pipeline_items';
  static const String colNotes = 'notes';
  static const String colDocuments = 'documents';
  static const String colInvestorWatchlists = 'investor_watchlists';
  static const String colInvestorBriefs = 'investor_briefs';
  static const String colAnalyticsDaily = 'analytics_daily';
  static const String colAnalyticsMonthly = 'analytics_monthly';
  static const String colManagerReviews = 'manager_reviews';
  static const String colAuditLogs = 'audit_logs';
  static const String colSystemHealth = 'system_health';
  static const String colAppSettings = 'app_settings';
  static const String colNews = 'news';
  static const String colOfficeActivity = 'office_activity';
  static const String colDeals = 'deals';
  /// Harici ilan sitelerinden çekilen ilanlar (Market Pulse – son atılan ilanlar).
  static const String colExternalListings = 'external_listings';
  /// Mülk Sağlık Karnesi: listing bazlı timeline (listings/{id}/property_vault).
  static const String colPropertyVault = 'property_vault';

  /// SharedPreferences anahtarları
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyLocale = 'locale';
  static const String keyLastUserId = 'last_user_id';

  /// Retry / timeout
  static const int maxRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration retryDelay = Duration(milliseconds: 500);

  /// AI token optimizasyonu: bu sürenin altındaki çağrılar derinlemesine analiz edilmez (maliyet/hız).
  static const int minCallDurationSecForAnalysis = 5;
  /// Yanlış numara / anlamsız çağrılar AI analizine sokulmaz.
  static const String callOutcomeWrongNumber = 'wrong_number';
  static const String callOutcomeCompleted = 'completed';

  /// Intelligence layer: sadece bu eşik ve üzeri ana ekrana düşer (Signal vs Noise).
  static const double opportunityRadarMinScore = 0.80;
  static const double hotLeadRadarMinScore = 0.80;

  /// Diyarbakır piyasa ayarları dokümanı (colAppSettings altında).
  static const String docMarketSettings = 'market_settings';
  static const String docIntelligenceMeta = 'intelligence_meta';
  /// İlan kaynakları & ofis ayarları: şehir, ilçe, şirket adı, logo (colAppSettings altında).
  static const String docListingDisplaySettings = 'listing_display_settings';
  /// War Room: aylık satış hedefi (ofis) (colAppSettings altında).
  static const String docOfficeTargets = 'office_targets';

  /// Stratejik alanlar (listings): Takas, Yatırım Radarı, Ses notu, AR/VR.
  static const String fieldSwapCompatible = 'swap_compatible';
  static const String fieldSwapCompatibilityScore = 'swap_compatibility_score';
  static const String fieldSwapCompatibilityVerdict = 'swap_compatibility_verdict';
  static const String fieldSwapCompatibilityUpdatedAt = 'swap_compatibility_updated_at';
  static const String fieldInvestmentScore = 'investment_score';
  static const String fieldInvestmentScoreUpdatedAt = 'investment_score_updated_at';
  static const String fieldHotspotTags = 'hotspot_tags';
  static const String fieldVoiceNoteSummary = 'voice_note_summary';
  static const String fieldMedia360Urls = 'media_360_urls';
  static const String fieldLidarScanId = 'lidar_scan_id';
  static const String fieldPropertyVaultDocId = 'property_vault_doc_id';

  /// Stratejik alanlar (customers/leads).
  static const String fieldVoiceNoteSummaryUpdatedAt = 'voice_note_summary_updated_at';
  static const String fieldIsVipInvestor = 'is_vip_investor';
  static const String fieldInvestmentAlertEnabled = 'investment_alert_enabled';
}
