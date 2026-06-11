import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Tema modu: 0 = system, 1 = light, 2 = dark
int themeModeIndexToStore(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 0;
    case ThemeMode.light:
      return 1;
    case ThemeMode.dark:
      return 2;
  }
}

ThemeMode themeModeFromIndex(int index) {
  switch (index) {
    case 0:
      return ThemeMode.system;
    case 1:
      return ThemeMode.light;
    case 2:
      return ThemeMode.dark;
    default:
      return ThemeMode.dark;
  }
}

/// Uygulama ayarlarını SharedPreferences ile yönetir (tema, bildirimler).
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Tema modu: 0=system, 1=light, 2=dark. Varsayılan 0 (Sistem — OS'u takip eder).
  Future<int> getThemeModeIndex() async {
    final prefs = await _storage;
    return prefs.getInt(AppConstants.keyThemeMode) ?? 0;
  }

  Future<void> setThemeModeIndex(int index) async {
    final prefs = await _storage;
    await prefs.setInt(AppConstants.keyThemeMode, index);
  }

  /// Bildirimler açık mı (push/in-app tercihi). Varsayılan true.
  Future<bool> getNotificationsEnabled() async {
    final prefs = await _storage;
    return prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await _storage;
    await prefs.setBool(AppConstants.keyNotificationsEnabled, value);
  }

  // ---------- Özellik bayrakları (ayarlardan aç/kapa). Varsayılan true = özellik açık ----------

  Future<bool> getFeatureFlag(String key, {bool defaultValue = true}) async {
    final prefs = await _storage;
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<Map<String, bool>> getFeatureFlagsSnapshot(
    List<String> keys, {
    required bool Function(String key) defaultFor,
  }) async {
    final prefs = await _storage;
    final out = <String, bool>{};
    for (final key in keys) {
      out[key] = prefs.getBool(key) ?? defaultFor(key);
    }
    return out;
  }

  Future<void> setFeatureFlag(String key, bool value) async {
    final prefs = await _storage;
    await prefs.setBool(key, value);
  }

  Future<bool> getContactSaveEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureContactSave);
  Future<bool> getWarRoomEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureWarRoom);
  Future<bool> getPipelineEnabled() =>
      getFeatureFlag(AppConstants.keyFeaturePipeline);
  Future<bool> getCommandCenterEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureCommandCenter);
  Future<bool> getInvestorIntelligenceEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureInvestorIntelligence);
  Future<bool> getAnalyticsEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureAnalytics);
  Future<bool> getCrashlyticsEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureCrashlytics);
  Future<bool> getPushNotificationsEnabled() =>
      getFeatureFlag(AppConstants.keyFeaturePushNotifications);
  Future<bool> getKpiBarEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureKpiBar);
  Future<bool> getPortfolioMatchEnabled() =>
      getFeatureFlag(AppConstants.keyFeaturePortfolioMatch);
  Future<bool> getTasksEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureTasks);
  Future<bool> getNotificationsCenterEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureNotificationsCenter);
  Future<bool> getCompactDashboard() =>
      getFeatureFlag(AppConstants.keyCompactDashboard, defaultValue: false);
  Future<bool> getHapticFeedbackEnabled() =>
      getFeatureFlag(AppConstants.keyHapticFeedback);
  Future<bool> getSoundEffectsEnabled() =>
      getFeatureFlag(AppConstants.keySoundEffects, defaultValue: false);

  Future<String> getNotificationSoundStyleId() async {
    final prefs = await _storage;
    return prefs.getString(AppConstants.keyNotificationSoundStyle) ??
        AppConstants.defaultNotificationSoundStyle;
  }

  Future<void> setNotificationSoundStyleId(String id) async {
    final prefs = await _storage;
    await prefs.setString(AppConstants.keyNotificationSoundStyle, id);
  }

  /// Batarya tasarrufu: animasyonları azaltır. Varsayılan false.
  Future<bool> getPowerSaverEnabled() async {
    final prefs = await _storage;
    return prefs.getBool(AppConstants.keyPowerSaver) ?? false;
  }

  Future<void> setPowerSaverEnabled(bool value) async {
    final prefs = await _storage;
    await prefs.setBool(AppConstants.keyPowerSaver, value);
  }

  /// Dil kodu: 'tr' veya 'en'. Kayıt yoksa cihaz dili (tr/en destekleniyorsa), değilse 'tr'.
  Future<String> getLocaleLanguageCode() async {
    final prefs = await _storage;
    final saved = prefs.getString(AppConstants.keyLocale);
    if (saved != null && saved.isNotEmpty) return saved;
    final platform =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return (platform == 'tr' || platform == 'en') ? platform : 'tr';
  }

  Future<void> setLocaleLanguageCode(String code) async {
    final prefs = await _storage;
    await prefs.setString(AppConstants.keyLocale, code);
  }

  /// Fırsat Endeksi / kişiselleştirilmiş piyasa özeti için tercih edilen ilçe.
  Future<String> getFavoriteInvestRegionId() async {
    final prefs = await _storage;
    return prefs.getString(AppConstants.keyFavoriteInvestRegion) ??
        AppConstants.defaultFavoriteInvestRegionId;
  }

  Future<void> setFavoriteInvestRegionId(String regionId) async {
    final prefs = await _storage;
    await prefs.setString(AppConstants.keyFavoriteInvestRegion, regionId);
  }

  // ---------- Erişilebilirlik: metin ölçeği ----------

  /// Kullanıcı metin ölçeği (0.85–1.30). Varsayılan 1.0.
  Future<double> getTextScale() async {
    final prefs = await _storage;
    final raw = prefs.getDouble(AppConstants.keyTextScale) ??
        AppConstants.defaultTextScale;
    return raw.clamp(AppConstants.minTextScale, AppConstants.maxTextScale);
  }

  Future<void> setTextScale(double value) async {
    final prefs = await _storage;
    final clamped =
        value.clamp(AppConstants.minTextScale, AppConstants.maxTextScale);
    await prefs.setDouble(AppConstants.keyTextScale, clamped);
  }

  // ---------- Kategori bazlı bildirim tercihleri ----------

  Future<bool> getNotifCategoryTasks() async =>
      (await _storage).getBool(AppConstants.keyNotifCategoryTasks) ?? true;
  Future<void> setNotifCategoryTasks(bool v) async =>
      (await _storage).setBool(AppConstants.keyNotifCategoryTasks, v);

  Future<bool> getNotifCategoryCalls() async =>
      (await _storage).getBool(AppConstants.keyNotifCategoryCalls) ?? true;
  Future<void> setNotifCategoryCalls(bool v) async =>
      (await _storage).setBool(AppConstants.keyNotifCategoryCalls, v);

  Future<bool> getNotifCategoryMessages() async =>
      (await _storage).getBool(AppConstants.keyNotifCategoryMessages) ?? true;
  Future<void> setNotifCategoryMessages(bool v) async =>
      (await _storage).setBool(AppConstants.keyNotifCategoryMessages, v);

  /// Axion Agent uyarıları (kayıtsız numara pop-up'ı). Varsayılan açık.
  Future<bool> getNotifCategoryAgent() async =>
      (await _storage).getBool(AppConstants.keyNotifCategoryAgent) ?? true;
  Future<void> setNotifCategoryAgent(bool v) async =>
      (await _storage).setBool(AppConstants.keyNotifCategoryAgent, v);

  /// Pazarlama bildirimleri varsayılan KAPALI (kullanıcı açıkça açar).
  Future<bool> getNotifCategoryMarketing() async =>
      (await _storage).getBool(AppConstants.keyNotifCategoryMarketing) ?? false;
  Future<void> setNotifCategoryMarketing(bool v) async =>
      (await _storage).setBool(AppConstants.keyNotifCategoryMarketing, v);

  // ---------- Sessiz saatler ----------

  Future<bool> getQuietHoursEnabled() async =>
      (await _storage).getBool(AppConstants.keyQuietHoursEnabled) ?? false;
  Future<void> setQuietHoursEnabled(bool v) async =>
      (await _storage).setBool(AppConstants.keyQuietHoursEnabled, v);

  Future<int> getQuietHoursStartMin() async =>
      (await _storage).getInt(AppConstants.keyQuietHoursStartMin) ??
      AppConstants.defaultQuietHoursStartMin;
  Future<void> setQuietHoursStartMin(int minuteOfDay) async =>
      (await _storage).setInt(AppConstants.keyQuietHoursStartMin, minuteOfDay);

  Future<int> getQuietHoursEndMin() async =>
      (await _storage).getInt(AppConstants.keyQuietHoursEndMin) ??
      AppConstants.defaultQuietHoursEndMin;
  Future<void> setQuietHoursEndMin(int minuteOfDay) async =>
      (await _storage).setInt(AppConstants.keyQuietHoursEndMin, minuteOfDay);

  /// Verilen an sessiz saat aralığında mı? Gece yarısını geçen aralıkları da
  /// (ör. 22:00–08:00) doğru değerlendirir.
  bool isWithinQuietHours({
    required bool enabled,
    required int startMin,
    required int endMin,
    required DateTime at,
  }) {
    if (!enabled) return false;
    if (startMin == endMin) return false; // boş aralık
    final nowMin = at.hour * 60 + at.minute;
    if (startMin < endMin) {
      return nowMin >= startMin && nowMin < endMin;
    }
    // Gece yarısını aşan aralık (ör. 22:00–08:00).
    return nowMin >= startMin || nowMin < endMin;
  }

  /// Bildirim kategorisi: 'tasks' | 'calls' | 'messages' | 'marketing'.
  /// Ana bildirim kapalıysa, kategori kapalıysa veya sessiz saatlerdeyse `false`.
  Future<bool> isNotificationAllowed(String category, {DateTime? at}) async {
    if (!await getNotificationsEnabled()) return false;

    final now = at ?? DateTime.now();
    final quiet = isWithinQuietHours(
      enabled: await getQuietHoursEnabled(),
      startMin: await getQuietHoursStartMin(),
      endMin: await getQuietHoursEndMin(),
      at: now,
    );
    if (quiet) return false;

    switch (category) {
      case 'tasks':
        return getNotifCategoryTasks();
      case 'calls':
        return getNotifCategoryCalls();
      case 'messages':
        return getNotifCategoryMessages();
      case 'marketing':
        return getNotifCategoryMarketing();
      case 'agent':
        return getNotifCategoryAgent();
      default:
        return true;
    }
  }
}
