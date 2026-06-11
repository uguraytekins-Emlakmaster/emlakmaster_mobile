import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';

/// Axion Agent için temel kart kabuğu — sakin, premium, abartısız.
class AxionAgentCard extends StatelessWidget {
  const AxionAgentCard({
    super.key,
    required this.child,
    this.highlight = false,
  });

  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: t.surfaceCardDecoration(highlight: highlight),
      child: child,
    );
  }
}
