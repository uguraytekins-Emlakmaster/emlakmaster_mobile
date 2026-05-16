import 'package:cloud_firestore/cloud_firestore.dart';

import 'team_message_entity.dart';

/// Son mesaj sayfası veya sayfalı eski mesaj yüklemesi sonucu.
class TeamMessagePage {
  const TeamMessagePage({
    required this.messages,
    required this.hasMore,
    this.oldestDoc,
  });

  /// `createdAt` azalan (en yeni önce).
  final List<TeamMessage> messages;

  /// Bir sonraki `startAfterDocument` imleci (en eski doküman).
  final DocumentSnapshot<Map<String, dynamic>>? oldestDoc;

  final bool hasMore;

  static const empty = TeamMessagePage(
    messages: [],
    hasMore: false,
  );
}
