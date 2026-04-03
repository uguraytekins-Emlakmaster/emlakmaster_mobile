/// Rainbow CRM / EmlakMaster – uygulama sabitleri. Magic string kullanmayın.
abstract final class AppConstants {
  AppConstants._();

  static const String appName = 'Rainbow CRM';
  static const String appShortName = 'EmlakMaster';
  /// Uygulama sürümü (pubspec ile senkron tutulur)
  static const String appVersion = '1.0.1+2';

  /// Firestore koleksiyon adları (spec ile uyumlu)
  static const String colUsers = 'users';
  /// Çok kiracılı ofis: `offices/{id}`.
  static const String colOffices = 'offices';
  /// Kullanıcı ↔ ofis üyeliği: `office_memberships/{id}`.
  static const String colOfficeMemberships = 'office_memberships';
  /// Kısa kodlu davetler: `office_invites/{id}` (code alanı ile sorgulanır).
  static const String colOfficeInvites = 'office_invites';
  static const String colRoles = 'roles';
  static const String colPermissions = 'permissions';
  static const String colAgents = 'agents';
  static const String colTeams = 'teams';
  /// Bekleyen davetler: email, role, teamId; ilk girişte users doc'a uygulanır.
  static const String colInvites = 'invites';
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
  /// Danışman bağlantıları: Sahibinden / Hepsiemlak / Emlakjet hesap bağlama.
  static const String colExternalConnections = 'external_connections';
  /// Bağlantı senkronu ile gelen ilanlar (Market Pulse [colExternalListings] ile ayrı tutulur).
  static const String colIntegrationListings = 'integration_listings';
  /// URL / dosya / uzantı içe aktarma görevleri (Cloud Functions yazar).
  static const String colListingImportTasks = 'listing_import_tasks';
  /// Senkron ve import logları (salt okuma).
  static const String colIntegrationSyncLogs = 'integration_sync_logs';
  /// Mülk Sağlık Karnesi: listing bazlı timeline (listings/{id}/property_vault).
  static const String colPropertyVault = 'property_vault';

  /// SharedPreferences anahtarları
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyLocale = 'locale';
  static const String keyLastUserId = 'last_user_id';
  /// Yatırım / Fırsat Endeksi için takip edilen bölge id (örn. `kayapinar`).
  static const String keyFavoriteInvestRegion = 'favorite_invest_region_id';
  static const String defaultFavoriteInvestRegionId = 'kayapinar';

  /// Özellik bayrakları (ayarlardan aç/kapa) — tüm özellikler tek yerden yönetilir
  static const String keyFeatureVoiceCrm = 'feature_voice_crm';
  static const String keyFeatureContactSave = 'feature_contact_save';
  static const String keyFeatureWarRoom = 'feature_war_room';
  static const String keyFeatureMarketPulse = 'feature_market_pulse';
  static const String keyFeatureDailyBrief = 'feature_daily_brief';
  static const String keyFeaturePipeline = 'feature_pipeline';
  static const String keyFeatureCommandCenter = 'feature_command_center';
  static const String keyFeatureInvestorIntelligence = 'feature_investor_intelligence';
  static const String keyFeatureAnalytics = 'feature_analytics';
  static const String keyFeatureCrashlytics = 'feature_crashlytics';
  static const String keyFeaturePushNotifications = 'feature_push_notifications';
  static const String keyFeatureKpiBar = 'feature_kpi_bar';
  static const String keyFeaturePortfolioMatch = 'feature_portfolio_match';
  static const String keyFeatureCallSummary = 'feature_call_summary';
  static const String keyFeatureTasks = 'feature_tasks';
  static const String keyFeatureNotificationsCenter = 'feature_notifications_center';
  static const String keyCompactDashboard = 'compact_dashboard';
  static const String keyHapticFeedback = 'haptic_feedback';
  static const String keySoundEffects = 'sound_effects';
  /// Batarya tasarrufu: animasyonları azaltır, arka planda iş yükünü düşürür.
  static const String keyPowerSaver = 'power_saver';
  /// Harici platform hesapları (Connected Accounts) — Phase 1 UI.
  static const String keyFeatureExternalIntegrations = 'feature_external_integrations';

  /// V1 odaklı (hafif) ürün: ikincil sekmeler ve analitik yükü azaltır; çekirdek CRM açık kalır.
  /// Varsayılan `true` — tam özellik seti için Ayarlardan kapatılabilir.
  static const String keyV1LeanProduct = 'v1_lean_product';

  /// Giriş ekranında Facebook butonu gösterilsin mi? (Facebook Developer + credentials hazır olunca true yap.)
  static const bool showFacebookLogin = false;

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
  /// Sunucu (Cloud Functions) rollup aktifken istemci demo keşif/heatmap yazımını kapatır — pil + tek doğruluk kaynağı.
  static const String docIntelligencePipeline = 'intelligence_pipeline';

  /// Blaze olmayan Spark: istemci rollup yazımları `analytics_daily` için (kurallarla eşleşmeli).
  static const String clientRollupSourceValue = 'client_rollup_v1';
  /// Aynı cihazda çok sık Firestore yazımını önler (pil / kota).
  static const Duration marketPulseClientRollupMinInterval = Duration(minutes: 30);
  static const String keyMarketPulseClientRollupLastMs = 'market_pulse_client_rollup_last_ms';
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
