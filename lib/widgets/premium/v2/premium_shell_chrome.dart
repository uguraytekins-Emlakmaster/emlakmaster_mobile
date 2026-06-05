import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Obsidian → navy gradient shell backdrop behind tab content.
class PremiumShellBackdrop extends StatelessWidget {
  const PremiumShellBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: premium.heroGradient),
      child: child,
    );
  }
}
