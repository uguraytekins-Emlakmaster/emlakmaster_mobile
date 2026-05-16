import 'dart:async';

import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/push_notification_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_presence.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ekip sohbeti FCM payload → [TeamThreadPage] yönlendirmesi.
class TeamChatPushNavigation {
  TeamChatPushNavigation._();

  static const String payloadType = 'team_chat';

  static Future<void> attach(WidgetRef ref) async {
    PushNotificationService.instance.setForegroundMessageHandler(
      (message) => _onForeground(ref, message),
    );
    PushNotificationService.instance.setMessageOpenedHandler(
      (message) => _openFromMessage(ref, message),
    );

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openFromMessage(ref, initial);
      });
    }
  }

  static void _onForeground(WidgetRef ref, RemoteMessage message) {
    final payload = parsePayload(message.data);
    if (payload == null) return;
    if (TeamChatPresence.isViewing(
      officeId: payload.officeId,
      channelId: payload.channelId,
    )) {
      return;
    }
    unawaited(AppFeedback.playNotification());
  }

  static void _openFromMessage(WidgetRef ref, RemoteMessage message) {
    final payload = parsePayload(message.data);
    if (payload == null) return;
    if (ref.read(currentUserProvider).valueOrNull == null) return;
    unawaited(openFromPayload(ref, payload));
  }

  static Future<void> openFromPayload(
    WidgetRef ref,
    TeamChatPushPayload payload,
  ) async {
    final enabled = await SettingsService.instance.getNotificationsEnabled();
    if (!enabled) return;
    if (ref.read(currentUserProvider).valueOrNull == null) return;

    final router = ref.read(AppRouter.goRouterProvider);
    router.push(
      AppRouter.routeMessageThread,
      extra: <String, dynamic>{
        'officeId': payload.officeId,
        'channelId': payload.channelId,
        'title': payload.title,
        'subtitle': payload.subtitle,
      },
    );
  }

  static TeamChatPushPayload? parsePayload(Map<String, dynamic> data) {
    if (data['type'] != payloadType) return null;
    final officeId = data['officeId'] as String? ?? '';
    final channelId = data['channelId'] as String? ?? '';
    if (officeId.isEmpty || channelId.isEmpty) return null;
    return TeamChatPushPayload(
      officeId: officeId,
      channelId: channelId,
      title: data['title'] as String? ?? 'Sohbet',
      subtitle: data['subtitle'] as String? ?? '',
    );
  }
}

class TeamChatPushPayload {
  const TeamChatPushPayload({
    required this.officeId,
    required this.channelId,
    required this.title,
    required this.subtitle,
  });

  final String officeId;
  final String channelId;
  final String title;
  final String subtitle;
}
