import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:flutter/material.dart';

/// Bağlantı rozeti — [PlatformConnectionTruthKind] renk; isteğe bağlı [labelOverride] ile metin (yaşam döngüsü).
class PlatformStatusChip extends StatelessWidget {
  const PlatformStatusChip({
    super.key,
    required this.truthKind,
    this.labelOverride,
  });

  final PlatformConnectionTruthKind truthKind;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final (Color bg, Color fg) = switch (truthKind) {
      PlatformConnectionTruthKind.liveConnected => (
          ext.success.withValues(alpha: 0.2),
          ext.success,
        ),
      PlatformConnectionTruthKind.mockDemo => (
          ext.warning.withValues(alpha: 0.2),
          ext.warning,
        ),
      PlatformConnectionTruthKind.preparing => (
          ext.accent.withValues(alpha: 0.18),
          ext.accent,
        ),
      PlatformConnectionTruthKind.experimentalNotLive => (
          ext.warning.withValues(alpha: 0.16),
          ext.warning,
        ),
      PlatformConnectionTruthKind.setupIncomplete => (
          ext.danger.withValues(alpha: 0.12),
          ext.danger,
        ),
      PlatformConnectionTruthKind.liveNotEnabled => (
          ext.foregroundMuted.withValues(alpha: 0.2),
          ext.foregroundSecondary,
        ),
    };
    final label = labelOverride ?? truthKind.shortLabelTr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
