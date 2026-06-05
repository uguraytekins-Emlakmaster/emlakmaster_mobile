import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/consultant_messages_tokens.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/models/message_conversation_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/message_list_row_quick_actions.dart';
import 'package:flutter/material.dart';

class MessageListPremiumTile extends StatelessWidget {
  const MessageListPremiumTile({
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
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ConsultantMessagesTokens.rowPaddingH,
          ConsultantMessagesTokens.rowPaddingV,
          ConsultantMessagesTokens.rowPaddingH,
          ConsultantMessagesTokens.rowPaddingV,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(
              imageUrl: item.avatarUrl,
              title: item.title,
              emphasize: item.kind == MessageConversationKind.general,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: ConsultantMessagesTokens.rowTitleSize,
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (snapshot.timeLabel != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          snapshot.timeLabel!,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (snapshot.showUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ext.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.unreadCount > 9 ? '9+' : '${item.unreadCount}',
                            style: TextStyle(
                              color: scheme.onError,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: ConsultantMessagesTokens.rowMetaSize,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.preview,
                    style: TextStyle(
                      color: snapshot.showUnread
                          ? ext.textPrimary.withValues(alpha: 0.9)
                          : ext.textTertiary,
                      fontSize: 11,
                      height: 1.25,
                      fontWeight:
                          snapshot.showUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _MiniChip(
                        label: snapshot.platformLabel,
                        fg: premium.champagneGold,
                      ),
                      _MiniChip(
                        label: snapshot.statusLabel,
                        fg: snapshot.showUnread ? ext.warning : ext.success,
                      ),
                      if (!snapshot.customerLinked)
                        _MiniChip(
                          label: 'Müşteri bağlı değil',
                          fg: ext.textTertiary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  MessageListRowQuickActions(
                    onOpen: onOpen,
                    onCall: onCall,
                    onWhatsApp: onWhatsApp,
                    onMarkRead: onMarkRead,
                    canOpen: snapshot.canOpenThread,
                    canCall: snapshot.canCall,
                    canWhatsApp: snapshot.canWhatsApp,
                    canMarkRead: snapshot.canMarkRead,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.title,
    this.imageUrl,
    this.emphasize = false,
  });

  final String title;
  final String? imageUrl;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    const size = ConsultantMessagesTokens.rowAvatarSize;
    final url = imageUrl?.trim();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: emphasize
          ? premium.champagneGold.withValues(alpha: 0.15)
          : ext.surfaceElevated,
      backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: url == null || url.isEmpty
          ? Icon(
              emphasize ? Icons.campaign_rounded : Icons.person_rounded,
              size: 22,
              color: emphasize ? premium.champagneGold : ext.textTertiary,
            )
          : null,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.fg});

  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
