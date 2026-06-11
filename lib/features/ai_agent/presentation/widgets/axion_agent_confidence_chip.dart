import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/axion_agent_enums.dart';

/// Güven çipi — veri tamlığına dayalı dürüst güven göstergesi.
class AxionAgentConfidenceChip extends StatelessWidget {
  const AxionAgentConfidenceChip({super.key, required this.confidence});

  final AxionAgentConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    final color = switch (confidence) {
      AxionAgentConfidence.high => t.success,
      AxionAgentConfidence.medium => t.info,
      AxionAgentConfidence.low => t.foregroundMuted,
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
        confidence.label,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
