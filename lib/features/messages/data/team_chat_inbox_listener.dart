import 'dart:async';

import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_local_notifications.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_presence.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_push_navigation.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_chat_inbox_item.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_inbox_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inbox stream → ses + yerel bildirim (FCM / billing gerekmez).
class TeamChatInboxListener {
  TeamChatInboxListener._();

  static final Set<String> _deliveredIds = <String>{};
  static bool _primed = false;
  static ProviderSubscription<AsyncValue<List<TeamChatInboxItem>>>? _inboxSub;
  static ProviderSubscription<AsyncValue<User?>>? _userSub;

  static void attach(WidgetRef ref) {
    TeamChatLocalNotifications.instance.onTap = (payload) {
      unawaited(TeamChatPushNavigation.openFromPayload(ref, payload));
    };

    _userSub?.close();
    _userSub = ref.listenManual(currentUserProvider, (previous, next) {
      _inboxSub?.close();
      _inboxSub = null;
      _deliveredIds.clear();
      _primed = false;

      final uid = next.valueOrNull?.uid;
      if (uid == null || uid.isEmpty) return;

      _inboxSub = ref.listenManual(
        teamChatInboxProvider(uid),
        (prev, nextInbox) => unawaited(
          _onInbox(ref, nextInbox),
        ),
      );
    });
  }

  static void detach() {
    _userSub?.close();
    _userSub = null;
    _inboxSub?.close();
    _inboxSub = null;
  }

  static Future<void> _onInbox(
    WidgetRef ref,
    AsyncValue<List<TeamChatInboxItem>> next,
  ) async {
    final items = next.valueOrNull;
    if (items == null) return;

    if (!_primed) {
      _primed = true;
      for (final item in items) {
        _deliveredIds.add(item.id);
      }
      return;
    }

    final allowed =
        await SettingsService.instance.isNotificationAllowed('messages');
    if (!allowed) return;

    for (final item in items) {
      if (_deliveredIds.contains(item.id)) continue;
      if (item.read) {
        _deliveredIds.add(item.id);
        continue;
      }
      if (TeamChatPresence.isViewing(
        officeId: item.officeId,
        channelId: item.channelId,
      )) {
        _deliveredIds.add(item.id);
        continue;
      }

      _deliveredIds.add(item.id);
      await AppFeedback.playNotification();

      final payload = TeamChatPushPayload(
        officeId: item.officeId,
        channelId: item.channelId,
        title: item.title,
        subtitle: item.subtitle,
      );

      await TeamChatLocalNotifications.instance.show(
        notificationId: item.id.hashCode & 0x7fffffff,
        title: item.title,
        body: item.body,
        payload: payload,
      );
    }
  }
}
