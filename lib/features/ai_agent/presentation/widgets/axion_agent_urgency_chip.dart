import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/axion_agent_enums.dart';

/// Aciliyet çipi — kural tabanlı aciliyet etiketi.
class AxionAgentUrgencyChip extends StatelessWidget {
  const AxionAgentUrgencyChip({super.key, required this.urgency});

  final AxionAgentUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    final color = switch (urgency) {
      AxionAgentUrgency.critical => t.danger,
      AxionAgentUrgency.high => t.warning,
      AxionAgentUrgency.medium => t.info,
      AxionAgentUrgency.low => t.foregroundMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: DesignTokens.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        urgency.label,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
