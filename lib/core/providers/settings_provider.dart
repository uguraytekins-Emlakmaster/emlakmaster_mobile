import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../services/settings_service.dart';

/// Başlangıçta main() içinde yüklenen tema indeksi (flash önlemek için).
/// Varsayılan 0 = Sistem (OS görünümünü takip eder).
final initialThemeModeIndexProvider = Provider<int>((ref) => 0);

/// Başlangıçta yüklenen dil kodu (tr/en).
final initialLocaleProvider = FutureProvider<Locale>((ref) async {
  final code = await SettingsService.instance.getLocaleLanguageCode();
  return Locale(code);
});

/// Uygulama dili. Güncellemek için setLocale.
final localeProvider = StateNotifierProvider<LocaleNotifier, AsyncValue<Locale>>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<AsyncValue<Locale>> {
  LocaleNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final code = await SettingsService.instance.getLocaleLanguageCode();
      state = AsyncValue.data(Locale(code));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setLocale(Locale locale) async {
    await SettingsService.instance.setLocaleLanguageCode(locale.languageCode);
    state = AsyncValue.data(locale);
  }
}

/// Tema modu indeksi: 0=system, 1=light, 2=dark. Güncellemek için setThemeModeIndex.
final themeModeIndexProvider =
    StateNotifierProvider<ThemeModeIndexNotifier, int>((ref) {
  final initial = ref.watch(initialThemeModeIndexProvider);
  return ThemeModeIndexNotifier(initial);
});

class ThemeModeIndexNotifier extends StateNotifier<int> {
  ThemeModeIndexNotifier(super.initial);

  /// Diskten okunan tema — runApp öncesi beklenmeden uygulanır.
  void restoreIndex(int index) {
    if (state == index) return;
    state = index;
  }

  Future<void> setThemeModeIndex(int index) async {
    await SettingsService.instance.setThemeModeIndex(index);
    state = index;
  }
}

/// [MaterialApp.themeMode] kaynağı. Ayarlar → Görünüm → Tema'dan
/// (sistem/açık/koyu) değiştirilir ve diske kaydedilir; varsayılan Sistem.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final index = ref.watch(themeModeIndexProvider);
  return themeModeFromIndex(index);
});

/// Erişilebilirlik metin ölçeği (0.85–1.30). MaterialApp builder'ında uygulanır.
final textScaleProvider =
    StateNotifierProvider<TextScaleNotifier, double>((ref) {
  return TextScaleNotifier();
});

class TextScaleNotifier extends StateNotifier<double> {
  TextScaleNotifier() : super(AppConstants.defaultTextScale) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await SettingsService.instance.getTextScale();
    } catch (_) {
      state = AppConstants.defaultTextScale;
    }
  }

  Future<void> setScale(double value) async {
    final clamped =
        value.clamp(AppConstants.minTextScale, AppConstants.maxTextScale);
    await SettingsService.instance.setTextScale(clamped);
    state = clamped;
  }
}

/// Bildirimler açık mı. İlk yüklemede Storage'dan okunur.
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, AsyncValue<bool>>((ref) {
  return NotificationsEnabledNotifier();
});

class NotificationsEnabledNotifier extends StateNotifier<AsyncValue<bool>> {
  NotificationsEnabledNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await SettingsService.instance.getNotificationsEnabled();
      state = AsyncValue.data(value);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setEnabled(bool value) async {
    await SettingsService.instance.setNotificationsEnabled(value);
    state = AsyncValue.data(value);
  }
}
