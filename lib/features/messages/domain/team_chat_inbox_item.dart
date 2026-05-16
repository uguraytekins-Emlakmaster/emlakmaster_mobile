import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}/team_chat_inbox/{messageId}` — kart/billing olmadan yerel bildirim kuyruğu.
class TeamChatInboxItem {
  const TeamChatInboxItem({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.officeId,
    required this.channelId,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.read,
    this.createdAt,
  });

  final String id;
  final String recipientId;
  final String senderId;
  final String officeId;
  final String channelId;
  final String title;
  final String subtitle;
  final String body;
  final bool read;
  final DateTime? createdAt;

  static TeamChatInboxItem? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    return TeamChatInboxItem(
      id: id,
      recipientId: data['recipientId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      officeId: data['officeId'] as String? ?? '',
      channelId: data['channelId'] as String? ?? '',
      title: data['title'] as String? ?? 'Sohbet',
      subtitle: data['subtitle'] as String? ?? '',
      body: data['body'] as String? ?? '',
      read: data['read'] as bool? ?? false,
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
