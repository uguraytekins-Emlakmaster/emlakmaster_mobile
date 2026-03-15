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
}
