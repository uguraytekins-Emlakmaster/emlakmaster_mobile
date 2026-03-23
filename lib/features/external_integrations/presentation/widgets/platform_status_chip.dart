import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_ui_state.dart';
import 'package:flutter/material.dart';

class PlatformStatusChip extends StatelessWidget {
  const PlatformStatusChip({super.key, required this.state});

  final PlatformConnectionUiState state;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final (bg, fg, label) = switch (state) {
      PlatformConnectionUiState.connected => (
          ext.success.withValues(alpha: 0.2),
          ext.success,
          state.shortLabel,
        ),
      PlatformConnectionUiState.disconnected => (
          ext.foregroundMuted.withValues(alpha: 0.2),
          ext.foregroundSecondary,
          state.shortLabel,
        ),
      PlatformConnectionUiState.limited => (
          DesignTokens.warning.withValues(alpha: 0.2),
          DesignTokens.warning,
          state.shortLabel,
        ),
      PlatformConnectionUiState.needsAttention => (
          ext.danger.withValues(alpha: 0.18),
          ext.danger,
          'İnceleme gerekli',
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
