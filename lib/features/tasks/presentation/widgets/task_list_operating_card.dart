import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Görev liste satırı kabuğu — blur yok.
class TaskListOperatingCard extends StatelessWidget {
  const TaskListOperatingCard({
    super.key,
    required this.child,
    this.emphasizeOverdue = false,
  });

  final Widget child;
  final bool emphasizeOverdue;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final borderColor = emphasizeOverdue
        ? ext.danger.withValues(alpha: 0.42)
        : premium.champagneGold.withValues(alpha: 0.2);
    final fill = emphasizeOverdue
        ? ext.danger.withValues(alpha: 0.06)
        : ext.card.withValues(alpha: 0.92);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: fill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        side: BorderSide(color: borderColor),
      ),
      child: child,
    );
  }
}
