import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_repository.dart';
import 'package:emlakmaster_mobile/features/messages/data/user_profile_cache.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_entity.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_type.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:flutter/foundation.dart';

/// Mesaj gönderildikten sonra alıcıların inbox koleksiyonuna yazar (FCM yerine).
class TeamChatInboxFanout {
  TeamChatInboxFanout._();

  static const String subcolInbox = 'team_chat_inbox';
  static const int _maxRecipientsPerMessage = 80;
  static const int _bodyMaxLen = 160;

  static Future<void> notifyRecipients({
    required String officeId,
    required String channelId,
    required String messageId,
    required String senderId,
    required String text,
  }) async {
    try {
      await FirestoreService.ensureInitialized();
      final channel = await _loadChannel(officeId, channelId);
      if (channel == null) return;

      final recipientIds = await _resolveRecipientIds(
        officeId: officeId,
        channel: channel,
        senderId: senderId,
      );
      if (recipientIds.isEmpty) return;

      final senderName = await _senderDisplayName(senderId);
      final title = _notificationTitle(channel, senderName);
      final subtitle = _notificationSubtitle(channel);
      final body = _truncateBody(text);

      final batch = FirebaseFirestore.instance.batch();
      var count = 0;
      for (final recipientId in recipientIds) {
        if (count >= _maxRecipientsPerMessage) break;
        final ref = FirebaseFirestore.instance
            .collection(AppConstants.colUsers)
            .doc(recipientId)
            .collection(subcolInbox)
            .doc(messageId);
        batch.set(ref, {
          'recipientId': recipientId,
          'senderId': senderId,
          'officeId': officeId,
          'channelId': channelId,
          'title': title,
          'subtitle': subtitle,
          'body': body,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
      await batch.commit();
    } catch (e, st) {
      if (kDebugMode) {
        AppLogger.e('TeamChatInboxFanout.notifyRecipients', e, st);
      }
    }
  }

  static Future<TeamChannel?> _loadChannel(
    String officeId,
    String channelId,
  ) async {
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.colOffices)
        .doc(officeId)
        .collection(TeamChatRepository.subcolTeamChannels)
        .doc(channelId)
        .get();
    if (!snap.exists) return null;
    return TeamChannel.fromFirestore(snap.id, snap.data());
  }

  static Future<List<String>> _resolveRecipientIds({
    required String officeId,
    required TeamChannel channel,
    required String senderId,
  }) async {
    if (channel.type == TeamChannelType.direct) {
      return channel.participantIds
          .where((id) => id.isNotEmpty && id != senderId)
          .toList();
    }

    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.colOfficeMemberships)
        .where('officeId', isEqualTo: officeId)
        .get();

    final ids = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['status'] != MembershipStatus.active.name) continue;
      final uid = data['userId'] as String?;
      if (uid == null || uid.isEmpty || uid == senderId) continue;
      ids.add(uid);
    }
    return ids.toList();
  }

  static Future<String> _senderDisplayName(String senderId) async {
    final doc = await UserProfileCache.instance.getMany([senderId]);
    final user = doc[senderId];
    final n = user?.name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = user?.email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return 'Ekip üyesi';
  }

  static String _notificationTitle(TeamChannel channel, String senderName) {
    if (channel.type == TeamChannelType.direct) return senderName;
    final t = channel.title?.trim();
    if (t != null && t.isNotEmpty) return '$senderName · $t';
    return '$senderName · Genel sohbet';
  }

  static String _notificationSubtitle(TeamChannel channel) {
    return channel.type == TeamChannelType.direct ? 'Birebir' : 'Ofis';
  }

  static String _truncateBody(String text) {
    final t = text.trim();
    if (t.length <= _bodyMaxLen) return t;
    return '${t.substring(0, _bodyMaxLen - 1)}…';
  }
}
