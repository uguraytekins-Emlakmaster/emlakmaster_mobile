import 'package:cloud_firestore/cloud_firestore.dart';

import 'team_channel_type.dart';

/// `offices/{officeId}/team_channels/{channelId}`
class TeamChannel {
  const TeamChannel({
    required this.id,
    required this.officeId,
    required this.type,
    required this.participantIds,
    this.title,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageBy,
    this.createdAt,
  });

  final String id;
  final String officeId;
  final TeamChannelType type;
  final List<String> participantIds;
  final String? title;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastMessageBy;
  final DateTime? createdAt;

  bool includesUser(String userId) {
    if (type == TeamChannelType.general) return true;
    return participantIds.contains(userId);
  }

  static TeamChannel? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final type = parseTeamChannelType(data['type'] as String?);
    if (type == null) return null;
    final participants = (data['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    return TeamChannel(
      id: id,
      officeId: data['officeId'] as String? ?? '',
      type: type,
      participantIds: participants,
      title: data['title'] as String?,
      lastMessageText: data['lastMessageText'] as String?,
      lastMessageAt: _ts(data['lastMessageAt']),
      lastMessageBy: data['lastMessageBy'] as String?,
      createdAt: _ts(data['createdAt']),
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
