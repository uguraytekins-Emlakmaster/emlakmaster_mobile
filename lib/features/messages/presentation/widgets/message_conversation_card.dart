import 'package:emlakmaster_mobile/features/messages/presentation/models/message_conversation_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/message_list_operating_card.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/message_list_premium_tile.dart';
import 'package:flutter/material.dart';

class MessageConversationCard extends StatelessWidget {
  const MessageConversationCard({
    super.key,
    required this.item,
    required this.snapshot,
    this.onTap,
    this.onOpen,
    this.onCall,
    this.onWhatsApp,
    this.onMarkRead,
  });

  final MessageConversationListItem item;
  final MessageConversationRowSnapshot snapshot;
  final VoidCallback? onTap;
  final VoidCallback? onOpen;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.title} konuşması',
      button: true,
      child: MessageListOperatingCard(
        emphasizeUnread: snapshot.showUnread,
        child: MessageListPremiumTile(
          item: item,
          snapshot: snapshot,
          onTap: onTap,
          onOpen: onOpen,
          onCall: onCall,
          onWhatsApp: onWhatsApp,
          onMarkRead: onMarkRead,
        ),
      ),
    );
  }
}
