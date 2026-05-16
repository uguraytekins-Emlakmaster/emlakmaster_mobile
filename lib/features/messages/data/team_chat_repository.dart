import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_entity.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_id.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_type.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_message_entity.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_inbox_fanout.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_message_page.dart';
import 'package:flutter/foundation.dart';

class TeamChatRepository {
  TeamChatRepository._();

  static const String subcolTeamChannels = 'team_channels';
  static const String subcolMessages = 'messages';

  static const int recentMessageLimit = 40;
  static const int olderMessagePageSize = 30;
  static const int directChannelQueryLimit = 40;

  static CollectionReference<Map<String, dynamic>> _channels(String officeId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.colOffices)
        .doc(officeId)
        .collection(subcolTeamChannels);
  }

  static CollectionReference<Map<String, dynamic>> _messages(
    String officeId,
    String channelId,
  ) {
    return _channels(officeId).doc(channelId).collection(subcolMessages);
  }

  /// Genel kanal + kullanıcının katıldığı direkt kanallar (hedefli sorgular).
  static Stream<List<TeamChannel>> watchChannelsForUser(
    String officeId,
    String userId,
  ) {
    final controller = StreamController<List<TeamChannel>>.broadcast();
    TeamChannel? general;
    var directs = <TeamChannel>[];

    void emit() {
      final merged = <TeamChannel>[];
      if (general != null) merged.add(general!);
      merged.addAll(directs);
      merged.sort((a, b) {
        final at = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      if (!controller.isClosed) controller.add(List.unmodifiable(merged));
    }

    late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
        generalSub;
    late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
        directSub;

    generalSub = _channels(officeId)
        .doc(kTeamGeneralChannelId)
        .snapshots(includeMetadataChanges: false)
        .listen(
      (snap) {
        general = snap.exists
            ? TeamChannel.fromFirestore(snap.id, snap.data())
            : null;
        emit();
      },
      onError: controller.addError,
    );

    directSub = _channels(officeId)
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .limit(directChannelQueryLimit)
        .snapshots(includeMetadataChanges: false)
        .listen(
      (snap) {
        directs = snap.docs
            .map((d) => TeamChannel.fromFirestore(d.id, d.data()))
            .whereType<TeamChannel>()
            .where((c) => c.type == TeamChannelType.direct)
            .toList(growable: false);
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await generalSub.cancel();
      await directSub.cancel();
    };

    return controller.stream;
  }

  /// Canlı kuyruk: en yeni [recentMessageLimit] mesaj.
  static Stream<TeamMessagePage> watchRecentMessages(
    String officeId,
    String channelId, {
    int limit = recentMessageLimit,
  }) {
    return _messages(officeId, channelId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: false)
        .map((snap) => _pageFromQuerySnapshot(snap, pageSize: limit));
  }

  /// Daha eski mesajlar (imleç: mevcut en eski doküman).
  static Future<TeamMessagePage> fetchOlderMessages({
    required String officeId,
    required String channelId,
    required DocumentSnapshot<Map<String, dynamic>> startAfter,
    int limit = olderMessagePageSize,
  }) async {
    await FirestoreService.ensureInitialized();
    final snap = await _messages(officeId, channelId)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(startAfter)
        .limit(limit)
        .get();
    return _pageFromQuerySnapshot(snap, pageSize: limit);
  }

  static TeamMessagePage _pageFromQuerySnapshot(
    QuerySnapshot<Map<String, dynamic>> snap, {
    required int pageSize,
  }) {
    final messages = snap.docs
        .map((d) => TeamMessage.fromFirestore(d.id, d.data()))
        .whereType<TeamMessage>()
        .toList(growable: false);
    final oldestDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    return TeamMessagePage(
      messages: messages,
      oldestDoc: oldestDoc,
      hasMore: messages.length >= pageSize,
    );
  }

  static Future<void> ensureGeneralChannel(String officeId) async {
    await FirestoreService.ensureInitialized();
    final ref = _channels(officeId).doc(kTeamGeneralChannelId);
    final existing = await ref.get();
    if (existing.exists) return;
    await ref.set({
      'type': teamChannelTypeToFirestore(TeamChannelType.general),
      'officeId': officeId,
      'participantIds': <String>[],
      'title': 'Genel',
      'lastMessageText': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String> ensureDirectChannel({
    required String officeId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    await FirestoreService.ensureInitialized();
    final channelId = teamDirectChannelId(currentUserId, otherUserId);
    final ref = _channels(officeId).doc(channelId);
    final existing = await ref.get();
    if (existing.exists) return channelId;
    final sorted = [currentUserId, otherUserId]..sort();
    await ref.set({
      'type': teamChannelTypeToFirestore(TeamChannelType.direct),
      'officeId': officeId,
      'participantIds': sorted,
      'lastMessageText': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return channelId;
  }

  static Future<void> sendTextMessage({
    required String officeId,
    required String channelId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await FirestoreService.ensureInitialized();
    final channelRef = _channels(officeId).doc(channelId);
    final messageRef = _messages(officeId, channelId).doc();
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(messageRef, {
        'senderId': senderId,
        'text': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(
        channelRef,
        {
          'lastMessageText': trimmed,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageBy': senderId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      unawaited(
        TeamChatInboxFanout.notifyRecipients(
          officeId: officeId,
          channelId: channelId,
          messageId: messageRef.id,
          senderId: senderId,
          text: trimmed,
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        AppLogger.e('TeamChatRepository.sendTextMessage', e, st);
      }
      rethrow;
    }
  }
}
