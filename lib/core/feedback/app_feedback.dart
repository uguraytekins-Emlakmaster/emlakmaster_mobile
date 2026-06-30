import 'package:audioplayers/audioplayers.dart';
import 'package:emlakmaster_mobile/core/feedback/app_sound.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Titreşim ve ses efektleri — ayarlardan okunur, tüm uygulama buradan kullanır.
class AppFeedback {
  AppFeedback._();

  static bool hapticEnabled = true;
  static bool soundEnabled = false;
  static AppNotificationSoundStyle notificationStyle =
      AppNotificationSoundStyle.chime;

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> initialize() async {
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (_) {}
    await syncFromSettings();
  }

  static Future<void> syncFromSettings() async {
    try {
      hapticEnabled =
          await SettingsService.instance.getHapticFeedbackEnabled();
      soundEnabled = await SettingsService.instance.getSoundEffectsEnabled();
      final styleId =
          await SettingsService.instance.getNotificationSoundStyleId();
      notificationStyle = AppNotificationSoundStyle.fromId(styleId);
    } catch (e, st) {
      AppLogger.e('AppFeedback.syncFromSettings', e, st);
    }
  }

  static void applyRuntimeFlags({
    bool? haptic,
    bool? sound,
    AppNotificationSoundStyle? style,
  }) {
    if (haptic != null) hapticEnabled = haptic;
    if (sound != null) soundEnabled = sound;
    if (style != null) notificationStyle = style;
  }

  // —— Haptic ——

  static Future<void> lightImpact() async {
    if (!hapticEnabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    if (!hapticEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavyImpact() async {
    if (!hapticEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> selectionClick() async {
    if (!hapticEnabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> vibrate() async {
    if (!hapticEnabled) return;
    await HapticFeedback.vibrate();
  }

  // —— Ses ——

  static bool get _isTestBinding {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('TestWidgetsFlutterBinding') ||
        name.contains('AutomatedTestWidgetsFlutterBinding');
  }

  static Future<void> play(AppSound sound, {bool force = false}) async {
    if (!force && !soundEnabled) return;
    if (kIsWeb || _isTestBinding) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(sound.assetPath));
    } catch (e, st) {
      AppLogger.e('AppFeedback.play ${sound.name}', e, st);
    }
  }

  static Future<void> playNotification({bool force = false}) async {
    try {
      final pushOn =
          await SettingsService.instance.getNotificationsEnabled();
      if (!pushOn && !force) return;
    } catch (_) {}
    // Bildirim sesi, "ses efektleri" anahtarından bağımsızdır.
    // Aksi halde kullanıcı bildirim ses stili seçse bile bildirim tonu duyulmayabilir.
    await play(notificationStyle.notificationSound, force: true);
  }

  static Future<void> playSuccess() => play(AppSound.success);

  static Future<void> playError() => play(AppSound.error);

  static Future<void> playWarning() => play(AppSound.warning);

  static Future<void> playTap() => play(AppSound.tap);

  static Future<void> playMessage() => play(AppSound.message);

  static Future<void> previewNotificationStyle(
    AppNotificationSoundStyle style,
  ) async {
    await play(style.notificationSound, force: true);
  }
}
