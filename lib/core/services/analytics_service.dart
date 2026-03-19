import 'package:firebase_analytics/firebase_analytics.dart';

/// Uygulama olayları ve ekran görüntüleme için Firebase Analytics sarmalayıcı.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Ekran görüntüleme (route/sayfa adı).
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (_) {
      // Analytics hatası uygulama akışını bozmasın.
    }
  }

  /// Özel olay: giriş, ilan tıklama, ayar değişikliği vb.
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (_) {
      // Analytics hatası uygulama akışını bozmasın.
    }
  }

  /// Kullanıcı giriş yaptı.
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'email');
    } catch (_) {}
  }

  /// Yeni kayıt (email veya google).
  Future<void> logSignUp({String method = 'email'}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (_) {}
  }

  /// İlan detayına tıklandı (listing_id vb.).
  Future<void> logListingView({String? listingId, String? source}) async {
    final params = <String, Object>{};
    if (listingId != null) params['listing_id'] = listingId;
    if (source != null) params['source'] = source;
    logEvent('listing_view', params.isEmpty ? null : params);
  }

  /// Ayar değişti (listing_display, tema vb.).
  Future<void> logSettingsChange({String? settingName}) async {
    if (settingName != null) logEvent('settings_change', {'setting': settingName});
  }
}
