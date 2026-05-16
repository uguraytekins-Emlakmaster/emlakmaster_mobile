import 'dart:convert';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_push_navigation.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Kart/billing olmadan sistem tepsisi bildirimi (Android/iOS).
class TeamChatLocalNotifications {
  TeamChatLocalNotifications._();

  static final TeamChatLocalNotifications instance =
      TeamChatLocalNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  void Function(TeamChatPushPayload payload)? onTap;

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
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'team_chat',
        'Ekip mesajları',
        description: 'Ofis içi sohbet bildirimleri',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<void> requestPermissionIfNeeded() async {
    if (!_supported || !_initialized) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> show({
    required int notificationId,
    required String title,
    required String body,
    required TeamChatPushPayload payload,
  }) async {
    if (!_supported || !_initialized) return;

    final payloadJson = jsonEncode({
      'type': TeamChatPushNavigation.payloadType,
      'officeId': payload.officeId,
      'channelId': payload.channelId,
      'title': payload.title,
      'subtitle': payload.subtitle,
    });

    const androidDetails = AndroidNotificationDetails(
      'team_chat',
      'Ekip mesajları',
      channelDescription: 'Ofis içi sohbet bildirimleri',
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
      payload: payloadJson,
    );
  }

  void _onResponse(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final payload = TeamChatPushNavigation.parsePayload(map);
      if (payload == null) return;
      onTap?.call(payload);
    } catch (e, st) {
      AppLogger.e('TeamChatLocalNotifications._onResponse', e, st);
    }
  }
}
