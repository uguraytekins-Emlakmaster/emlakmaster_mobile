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

  /// Tema modu: 0=system, 1=light, 2=dark. Varsayılan 2 (koyu).
  Future<int> getThemeModeIndex() async {
    final prefs = await _storage;
    return prefs.getInt(AppConstants.keyThemeMode) ?? 2;
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

  Future<void> setFeatureFlag(String key, bool value) async {
    final prefs = await _storage;
    await prefs.setBool(key, value);
  }

  Future<bool> getVoiceCrmEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureVoiceCrm);
  Future<bool> getContactSaveEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureContactSave);
  Future<bool> getWarRoomEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureWarRoom);
  Future<bool> getMarketPulseEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureMarketPulse);
  Future<bool> getDailyBriefEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureDailyBrief);
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
  Future<bool> getCallSummaryEnabled() =>
      getFeatureFlag(AppConstants.keyFeatureCallSummary);
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
    final platform = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return (platform == 'tr' || platform == 'en') ? platform : 'tr';
  }

  Future<void> setLocaleLanguageCode(String code) async {
    final prefs = await _storage;
    await prefs.setString(AppConstants.keyLocale, code);
  }
}
