import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/axion_agent_enums.dart';
import '../../domain/axion_agent_models.dart';
import 'axion_agent_action_buttons.dart';
import 'axion_agent_card.dart';
import 'axion_agent_confidence_chip.dart';
import 'axion_agent_honesty_note.dart';
import 'axion_agent_urgency_chip.dart';

/// Tek öneri kartı: başlık + açıklama + sebep + çipler + dürüstlük notu +
/// onay gerektiren eylem butonları + kaynak etiketi.
class AxionAgentSuggestionCard extends StatelessWidget {
  const AxionAgentSuggestionCard({
    super.key,
    required this.suggestion,
    this.onReview,
    this.onCreateTask,
    this.onDraftMessage,
    this.onReject,
  });

  final AxionAgentSuggestion suggestion;
  final VoidCallback? onReview;
  final VoidCallback? onCreateTask;
  final VoidCallback? onDraftMessage;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return AxionAgentCard(
      highlight: suggestion.urgency == AxionAgentUrgency.critical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  suggestion.title,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBase,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              AxionAgentUrgencyChip(urgency: suggestion.urgency),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            suggestion.description,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSm,
              color: t.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Sebep: ${suggestion.reason}',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXs,
              color: t.textTertiary,
              height: 1.35,
            ),
          ),
          if (suggestion.evidence.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space1),
            for (final e in suggestion.evidence)
              Text(
                '• $e',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXs,
                  color: t.textTertiary,
                ),
              ),
          ],
          const SizedBox(height: DesignTokens.space3),
          Row(
            children: [
              AxionAgentConfidenceChip(confidence: suggestion.confidence),
              const SizedBox(width: DesignTokens.space2),
              Text(
                suggestion.sourceType.label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXs,
                  color: t.textPassive,
                ),
              ),
            ],
          ),
          if (suggestion.honestyNote != null) ...[
            const SizedBox(height: DesignTokens.space2),
            AxionAgentHonestyNote(note: suggestion.honestyNote!),
          ],
          const SizedBox(height: DesignTokens.space3),
          AxionAgentActionButtons(
            suggestion: suggestion,
            onReview: onReview,
            onCreateTask: onCreateTask,
            onDraftMessage: onDraftMessage,
            onReject: onReject,
          ),
        ],
      ),
    );
  }
}
