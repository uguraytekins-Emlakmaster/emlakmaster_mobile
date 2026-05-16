import 'package:cloud_firestore/cloud_firestore.dart';

/// `offices/{officeId}/team_channels/{channelId}/messages/{messageId}`
class TeamMessage {
  const TeamMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  static TeamMessage? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final text = data['text'] as String?;
    if (text == null || text.isEmpty) return null;
    return TeamMessage(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      text: text,
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
