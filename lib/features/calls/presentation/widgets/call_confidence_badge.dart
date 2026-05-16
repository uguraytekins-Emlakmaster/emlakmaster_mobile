import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/domain/call_confidence.dart';
import 'package:flutter/material.dart';

/// Çağrı kaynağı güven göstergesi — tek satır, abartısız.
class CallConfidenceBadge extends StatelessWidget {
  const CallConfidenceBadge({
    super.key,
    required this.kind,
    this.compact = true,
  });

  final CallConfidenceKind kind;
  final bool compact;

  static Widget? maybeFromStartedFromScreen(String? screen) {
    final k = CallConfidenceLabels.fromStartedFromScreen(screen);
    if (k == null) return null;
    return CallConfidenceBadge(kind: k);
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final label = CallConfidenceLabels.label(kind);
    final color = switch (kind) {
      CallConfidenceKind.emlakMasterOriginated => ext.success,
      CallConfidenceKind.manualRecord => ext.textTertiary,
      CallConfidenceKind.callbackPending => ext.warning,
      CallConfidenceKind.deviceLog => ext.info,
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DesignTokens.space2 : DesignTokens.space3,
        vertical: compact ? 3 : DesignTokens.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10.5 : 11,
              letterSpacing: 0.02,
            ),
      ),
    );
  }
}
