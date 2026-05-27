import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class MessageListOperatingCard extends StatelessWidget {
  const MessageListOperatingCard({
    super.key,
    required this.child,
    this.emphasizeUnread = false,
  });

  final Widget child;
  final bool emphasizeUnread;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ext.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: emphasizeUnread
              ? ext.warning.withValues(alpha: 0.5)
              : ext.border.withValues(alpha: 0.4),
          width: emphasizeUnread ? 1.2 : 1,
        ),
      ),
      child: child,
    );
  }
}
