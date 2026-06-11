import 'dart:async';

import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/push_notification_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CRM FCM payload tipleri — Cloud Functions / Admin SDK ile uyumlu.
abstract final class CrmPushPayloadType {
  static const String executionReminder = 'execution_reminder';
  static const String taskDue = 'task_due';
  static const String customer = 'customer';
  static const String listing = 'listing';
}

/// Tek giriş: tüm FCM türleri → go_router.
class CrmPushNavigation {
  CrmPushNavigation._();

  static Future<void> attach(WidgetRef ref) async {
    PushNotificationService.instance.setForegroundMessageHandler(
      (message) => _onForeground(ref, message),
    );
    PushNotificationService.instance.setMessageOpenedHandler(
      (message) => unawaited(_openFromMessage(ref, message)),
    );
    PushNotificationService.instance.onTokenRefresh((token) async {
      final uid = ref.read(currentUserProvider).valueOrNull?.uid;
      if (uid == null || uid.isEmpty) return;
      await PushNotificationService.instance.refreshTokenAndSaveToFirestore(uid);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_openFromMessage(ref, initial));
      });
    }
  }

  static void _onForeground(WidgetRef ref, RemoteMessage message) {
    unawaited(AppFeedback.playNotification());
  }

  static Future<void> _openFromMessage(
    WidgetRef ref,
    RemoteMessage message,
  ) async {
    if (ref.read(currentUserProvider).valueOrNull == null) return;
    final enabled = await SettingsService.instance.getNotificationsEnabled();
    if (!enabled) return;

    final data = message.data;
    final router = ref.read(AppRouter.goRouterProvider);
    final type = data['type'] as String? ?? '';

    switch (type) {
      case CrmPushPayloadType.executionReminder:
      case CrmPushPayloadType.customer:
        final customerId = data['customerId'] as String? ?? '';
        if (customerId.isNotEmpty) {
          router.push('/customer/$customerId');
        }
        return;
      case CrmPushPayloadType.taskDue:
        final customerId = data['customerId'] as String? ?? '';
        if (customerId.isNotEmpty) {
          router.push('/customer/$customerId');
          return;
        }
        ref.read(mainShellShortcutProvider.notifier).enqueue(
              MainShellShortcut.openTasksTab,
            );
        router.go(AppRouter.routeHome);
        return;
      case CrmPushPayloadType.listing:
        final listingId = data['listingId'] as String? ?? '';
        if (listingId.isNotEmpty) {
          router.push(
            AppRouter.routeListingDetail.replaceFirst(':id', listingId),
          );
        }
        return;
      default:
        return;
    }
  }
}
