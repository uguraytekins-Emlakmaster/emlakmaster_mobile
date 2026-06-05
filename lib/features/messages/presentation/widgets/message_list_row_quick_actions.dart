import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/consultant_messages_tokens.dart';
import 'package:flutter/material.dart';

class MessageListRowQuickActions extends StatelessWidget {
  const MessageListRowQuickActions({
    super.key,
    this.onOpen,
    this.onCall,
    this.onWhatsApp,
    this.onMarkRead,
    this.canOpen = true,
    this.canCall = false,
    this.canWhatsApp = false,
    this.canMarkRead = false,
  });

  final VoidCallback? onOpen;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onMarkRead;
  final bool canOpen;
  final bool canCall;
  final bool canWhatsApp;
  final bool canMarkRead;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.chat_bubble_outline_rounded,
          color: premium.champagneGold.withValues(alpha: 0.9),
          tooltip: 'Sohbet',
          onPressed: canOpen ? onOpen : null,
        ),
        _ActionIcon(
          icon: Icons.call_outlined,
          color: ext.info,
          tooltip: 'Ara',
          onPressed: canCall ? onCall : onCall,
        ),
        _ActionIcon(
          icon: Icons.chat_rounded,
          color: const Color(0xFF25D366),
          tooltip: 'WhatsApp',
          onPressed: canWhatsApp ? onWhatsApp : onWhatsApp,
        ),
        _ActionIcon(
          icon: Icons.mark_chat_read_outlined,
          color: ext.textSecondary,
          tooltip: 'Okundu',
          onPressed: canMarkRead ? onMarkRead : onMarkRead,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: ConsultantMessagesTokens.actionTapSize,
        minHeight: ConsultantMessagesTokens.actionTapSize,
      ),
      icon: Icon(
        icon,
        size: ConsultantMessagesTokens.actionIconSize,
        color: enabled
            ? color
            : AppThemeExtension.of(context)
                .textTertiary
                .withValues(alpha: 0.35),
      ),
    );
  }
}
