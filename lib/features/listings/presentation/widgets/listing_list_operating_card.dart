import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// İlan satırı kabuğu — dikkat gerektiren kayıtlar için hafif vurgu.
class ListingListOperatingCard extends StatelessWidget {
  const ListingListOperatingCard({
    super.key,
    required this.child,
    this.emphasizeAttention = false,
  });

  final Widget child;
  final bool emphasizeAttention;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ext.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: emphasizeAttention
              ? ext.warning.withValues(alpha: 0.45)
              : ext.border.withValues(alpha: 0.4),
          width: emphasizeAttention ? 1.2 : 1,
        ),
      ),
      child: child,
    );
  }
}
