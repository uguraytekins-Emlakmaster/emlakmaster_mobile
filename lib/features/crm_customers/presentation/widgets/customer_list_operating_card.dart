import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Liste satırı kabuğu — blur yok, hafif champagne kenarlık.
class CustomerListOperatingCard extends StatelessWidget {
  const CustomerListOperatingCard({
    super.key,
    required this.child,
    this.selected = false,
  });

  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final borderColor = selected
        ? premium.champagneGold.withValues(alpha: 0.45)
        : premium.champagneGold.withValues(alpha: 0.2);
    final fill = selected
        ? premium.champagneGold.withValues(alpha: 0.08)
        : ext.card.withValues(alpha: 0.92);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: fill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        side: BorderSide(color: borderColor, width: selected ? 1.2 : 1),
      ),
      child: child,
    );
  }
}
