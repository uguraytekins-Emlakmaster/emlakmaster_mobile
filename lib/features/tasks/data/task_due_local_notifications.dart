import 'dart:convert';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Görev vadesi — yerel hatırlatma (FCM öncesi).
class TaskDueLocalNotifications {
  TaskDueLocalNotifications._();

  static final TaskDueLocalNotifications instance = TaskDueLocalNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(String taskId, String? customerId)? onTap;

  bool get _supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> ensureInitialized() async {
    if (_initialized || !_supported) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onResponse,
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'task_due',
        'Görev hatırlatıcıları',
        description: 'Vadesi gelen veya geçen görevler',
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    _initialized = true;
  }

  Future<void> showTaskDue({
    required int notificationId,
    required String title,
    required String body,
    String? taskId,
    String? customerId,
  }) async {
    if (!_supported || !_initialized) return;
    final payload = jsonEncode({
      'type': 'task_due',
      if (taskId != null) 'taskId': taskId,
      if (customerId != null) 'customerId': customerId,
    });
    await _plugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_due',
          'Görev hatırlatıcıları',
          channelDescription: 'Vadesi gelen veya geçen görevler',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _onResponse(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['type'] != 'task_due') return;
      onTap?.call(
        map['taskId'] as String? ?? '',
        map['customerId'] as String?,
      );
    } catch (e, st) {
      AppLogger.e('TaskDueLocalNotifications._onResponse', e, st);
    }
  }
}
