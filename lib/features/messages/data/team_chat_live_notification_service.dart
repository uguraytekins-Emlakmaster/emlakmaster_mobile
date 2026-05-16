import 'dart:async';

import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_presence.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_entity.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uygulama açıkken yeni ekip mesajı — Cloud Function olmadan ses/geri bildirim.
/// (Uygulama tamamen kapalıyken FCM için [onTeamChatMessageCreated] gerekir.)
class TeamChatLiveNotificationService {
  TeamChatLiveNotificationService._();

  static bool _primed = false;

  static void attach(WidgetRef ref) {
    ref.listen(teamChannelsProvider, (previous, next) {
      final uid = ref.read(currentUserProvider).valueOrNull?.uid;
      if (uid == null) return;
      final channels = next.valueOrNull;
      if (channels == null) return;

      if (!_primed) {
        _primed = true;
        return;
      }

      final prevList = previous?.valueOrNull ?? const <TeamChannel>[];
      final prevMap = {for (final c in prevList) c.id: c};

      for (final channel in channels) {
        if (!_shouldNotify(channel: channel, uid: uid, prevMap: prevMap)) {
          continue;
        }
        unawaited(AppFeedback.playNotification());
        return;
      }
    });

    ref.listen(currentUserProvider, (prev, next) {
      if (next.valueOrNull?.uid == null) {
        _primed = false;
      }
    });
  }

  static bool _shouldNotify({
    required TeamChannel channel,
    required String uid,
    required Map<String, TeamChannel> prevMap,
  }) {
    final senderId = channel.lastMessageBy;
    if (senderId == null || senderId == uid) return false;
    final at = channel.lastMessageAt;
    if (at == null) return false;
    if (TeamChatPresence.isViewing(
      officeId: channel.officeId,
      channelId: channel.id,
    )) {
      return false;
    }

    final prev = prevMap[channel.id];
    if (prev == null) return true;
    if (prev.lastMessageAt != at) return true;
    return prev.lastMessageText != channel.lastMessageText;
  }
}
