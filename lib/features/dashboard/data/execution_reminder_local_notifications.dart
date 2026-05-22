import 'dart:convert';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// İcra hatırlatıcıları — FCM olmadan yerel özet bildirimi (Android/iOS).
class ExecutionReminderLocalNotifications {
  ExecutionReminderLocalNotifications._();

  static final ExecutionReminderLocalNotifications instance =
      ExecutionReminderLocalNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(String customerId)? onTapCustomer;

  bool get _supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> ensureInitialized() async {
    if (_initialized || !_supported) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onResponse,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'execution_reminders',
        'İcra hatırlatıcıları',
        description: 'Bugün yapılması gereken müşteri adımları',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<void> showSummary({
    required int notificationId,
    required String title,
    required String body,
    required String customerId,
  }) async {
    if (!_supported || !_initialized) return;

    final payload = jsonEncode({
      'type': 'execution_reminder',
      'customerId': customerId,
    });

    const androidDetails = AndroidNotificationDetails(
      'execution_reminders',
      'İcra hatırlatıcıları',
      channelDescription: 'Bugün yapılması gereken müşteri adımları',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  void _onResponse(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['type'] != 'execution_reminder') return;
      final customerId = map['customerId'] as String?;
      if (customerId == null || customerId.isEmpty) return;
      onTapCustomer?.call(customerId);
    } catch (e, st) {
      AppLogger.e('ExecutionReminderLocalNotifications._onResponse', e, st);
    }
  }
}
