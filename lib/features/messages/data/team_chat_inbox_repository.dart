import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_inbox_fanout.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_chat_inbox_item.dart';

class TeamChatInboxRepository {
  TeamChatInboxRepository._();

  static CollectionReference<Map<String, dynamic>> _inbox(String userId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(TeamChatInboxFanout.subcolInbox);
  }

  static Stream<List<TeamChatInboxItem>> watchInbox(String userId) {
    return _inbox(userId)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots(includeMetadataChanges: false)
        .map((snap) {
      return snap.docs
          .map((d) => TeamChatInboxItem.fromFirestore(d.id, d.data()))
          .whereType<TeamChatInboxItem>()
          .toList(growable: false);
    });
  }
}
