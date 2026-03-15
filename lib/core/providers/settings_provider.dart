import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

/// Başlangıçta main() içinde yüklenen tema indeksi (flash önlemek için).
final initialThemeModeIndexProvider = Provider<int>((ref) => 2);

/// Tema modu indeksi: 0=system, 1=light, 2=dark. Güncellemek için setThemeModeIndex.
final themeModeIndexProvider =
    StateNotifierProvider<ThemeModeIndexNotifier, int>((ref) {
  final initial = ref.watch(initialThemeModeIndexProvider);
  return ThemeModeIndexNotifier(initial);
});

class ThemeModeIndexNotifier extends StateNotifier<int> {
  ThemeModeIndexNotifier(super.initial);

  Future<void> setThemeModeIndex(int index) async {
    await SettingsService.instance.setThemeModeIndex(index);
    state = index;
  }
}

/// ThemeMode olarak kullanmak için (MaterialApp.themeMode).
final themeModeProvider = Provider<ThemeMode>((ref) {
  final index = ref.watch(themeModeIndexProvider);
  return themeModeFromIndex(index);
});

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
