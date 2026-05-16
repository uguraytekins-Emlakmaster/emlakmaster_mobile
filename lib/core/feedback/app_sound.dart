/// Uygulama içi ses kimlikleri ve asset yolları.
enum AppNotificationSoundStyle {
  chime('chime', 'notification_chime.wav'),
  sparkle('sparkle', 'notification_sparkle.wav'),
  bell('bell', 'notification_bell.wav');

  const AppNotificationSoundStyle(this.id, this.fileName);

  final String id;
  final String fileName;

  static AppNotificationSoundStyle fromId(String? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return chime;
  }
}

enum AppSound {
  notificationChime('sounds/notification_chime.wav'),
  notificationSparkle('sounds/notification_sparkle.wav'),
  notificationBell('sounds/notification_bell.wav'),
  success('sounds/success.wav'),
  error('sounds/error.wav'),
  warning('sounds/warning.wav'),
  tap('sounds/tap.wav'),
  message('sounds/message.wav');

  const AppSound(this.assetPath);

  final String assetPath;
}

extension AppNotificationSoundStyleX on AppNotificationSoundStyle {
  AppSound get notificationSound {
    switch (this) {
      case AppNotificationSoundStyle.chime:
        return AppSound.notificationChime;
      case AppNotificationSoundStyle.sparkle:
        return AppSound.notificationSparkle;
      case AppNotificationSoundStyle.bell:
        return AppSound.notificationBell;
    }
  }
}
