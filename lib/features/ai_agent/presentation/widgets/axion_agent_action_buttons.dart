import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/axion_agent_models.dart';

/// Öneri eylem butonları.
///
/// "Tamamlandı" ASLA otomatik değildir — tüm eylemler kullanıcı onayı ister.
class AxionAgentActionButtons extends StatelessWidget {
  const AxionAgentActionButtons({
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
    return Wrap(
      spacing: DesignTokens.space2,
      runSpacing: DesignTokens.space1,
      children: [
        if (onReview != null)
          _ActionButton(label: 'İncele', color: t.accent, onTap: onReview!),
        if (onCreateTask != null)
          _ActionButton(
            label: 'Görev aç',
            color: t.accent,
            onTap: onCreateTask!,
          ),
        if (onDraftMessage != null)
          _ActionButton(
            label: 'Mesaj taslağı',
            color: t.info,
            onTap: onDraftMessage!,
          ),
        if (onReject != null)
          _ActionButton(
            label: 'Reddet',
            color: t.foregroundMuted,
            onTap: onReject!,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
