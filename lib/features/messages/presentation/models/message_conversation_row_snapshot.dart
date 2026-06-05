import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';

/// Satır başına türetilmiş etiketler.
class MessageConversationRowSnapshot {
  const MessageConversationRowSnapshot({
    required this.platformLabel,
    required this.statusLabel,
    required this.timeLabel,
    required this.showUnread,
    required this.customerLinked,
    required this.canOpenThread,
    required this.canCall,
    required this.canWhatsApp,
    required this.canMarkRead,
  });

  final String platformLabel;
  final String statusLabel;
  final String? timeLabel;
  final bool showUnread;
  final bool customerLinked;
  final bool canOpenThread;
  final bool canCall;
  final bool canWhatsApp;
  final bool canMarkRead;

  factory MessageConversationRowSnapshot.fromItem(
    MessageConversationListItem item,
  ) {
    final platformLabel = item.isTeamLive ? 'Ekip' : 'Önizleme';
    final statusLabel = switch (item.kind) {
      MessageConversationKind.general => 'Genel',
      MessageConversationKind.direct => item.unreadCount > 0 ? 'Okunmadı' : 'Güncel',
      MessageConversationKind.memberStart => 'Başlat',
    };

    String? timeLabel;
    final at = item.lastMessageAt;
    if (at != null) {
      final now = DateTime.now();
      final diff = now.difference(at);
      if (diff.inMinutes < 60) {
        timeLabel = '${diff.inMinutes} dk';
      } else if (diff.inHours < 24) {
        timeLabel = '${diff.inHours} sa';
      } else {
        timeLabel = '${at.day}.${at.month}';
      }
    }

    return MessageConversationRowSnapshot(
      platformLabel: platformLabel,
      statusLabel: statusLabel,
      timeLabel: timeLabel,
      showUnread: item.unreadCount > 0,
      customerLinked: false,
      canOpenThread: item.isTeamLive && item.channelId != null,
      canCall: false,
      canWhatsApp: false,
      canMarkRead: item.unreadCount > 0,
    );
  }
}
