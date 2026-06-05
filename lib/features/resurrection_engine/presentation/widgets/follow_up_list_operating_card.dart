import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Takip satırı kabuğu — acil geri kazanım için hafif vurgu.
class FollowUpListOperatingCard extends StatelessWidget {
  const FollowUpListOperatingCard({
    super.key,
    required this.child,
    this.emphasizeUrgent = false,
  });

  final Widget child;
  final bool emphasizeUrgent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ext.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: emphasizeUrgent
              ? ext.warning.withValues(alpha: 0.5)
              : ext.border.withValues(alpha: 0.4),
          width: emphasizeUrgent ? 1.2 : 1,
        ),
      ),
      child: child,
    );
  }
}
