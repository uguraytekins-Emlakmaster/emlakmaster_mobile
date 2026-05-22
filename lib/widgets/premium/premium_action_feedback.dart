import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';

enum PremiumActionFeedbackType {
  info,
  success,
  warning,
  error,
  comingSoon,
}

/// Tıklanabilir öğeler için standart premium geri bildirim (sheet veya kısa snack).
Future<void> showPremiumActionFeedback(
  BuildContext context, {
  required String title,
  required String message,
  PremiumActionFeedbackType type = PremiumActionFeedbackType.info,
  bool useSheet = true,
}) async {
  await AppFeedback.lightImpact();
  if (!context.mounted) return;

  if (!useSheet) {
    _showStyledSnackBar(context, title: title, message: message, type: type);
    return;
  }

  final ext = AppThemeExtension.of(context);
  final (icon, accent) = _styleFor(type, ext);

  await showPremiumScrollableBottomSheet<void>(
    context: context,
    maxHeightFactor: 0.42,
    builder: (ctx) => PremiumScrollableBottomSheetShell(
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(DesignTokens.radiusControl),
            ),
            child: Icon(icon, color: accent, size: DesignTokens.iconLg),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: PremiumSheetHeader(
              compact: true,
              title: title,
              subtitle: message,
            ),
          ),
          IconButton(
            tooltip: 'Kapat',
            onPressed: () => Navigator.of(ctx).pop(),
            icon: Icon(Icons.close_rounded, color: ext.textSecondary),
          ),
        ],
      ),
      bottomActions: FilledButton(
        onPressed: () => Navigator.of(ctx).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: ext.accent,
          foregroundColor: ext.onBrand,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
          ),
        ),
        child: Text(
          type == PremiumActionFeedbackType.comingSoon ? 'Anladım' : 'Tamam',
          style: AppTypography.bodyStrong(ctx).copyWith(color: ext.onBrand),
        ),
      ),
      child: const SizedBox.shrink(),
    ),
  );
}

Future<void> showPremiumComingSoon(
  BuildContext context, {
  required String title,
  String? message,
}) {
  return showPremiumActionFeedback(
    context,
    title: title,
    message: message ??
        'Bu özellik hazırlanıyor. Yakında aktif olacak; şimdilik ilgili akışı manuel yönetebilirsiniz.',
    type: PremiumActionFeedbackType.comingSoon,
  );
}

void _showStyledSnackBar(
  BuildContext context, {
  required String title,
  required String message,
  required PremiumActionFeedbackType type,
}) {
  final ext = AppThemeExtension.of(context);
  final (_, accent) = _styleFor(type, ext);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ext.surfaceElevated,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyStrong(context).copyWith(
              color: ext.textPrimary,
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              message,
              style: AppTypography.body(context).copyWith(
                color: ext.textSecondary,
                fontSize: DesignTokens.fontSizeSm,
              ),
            ),
          ],
        ],
      ),
      action: SnackBarAction(
        label: 'Tamam',
        textColor: accent,
        onPressed: () {},
      ),
    ),
  );
}

(IconData icon, Color accent) _styleFor(
  PremiumActionFeedbackType type,
  AppThemeExtension ext,
) {
  return switch (type) {
    PremiumActionFeedbackType.success => (
        Icons.check_circle_rounded,
        ext.success,
      ),
    PremiumActionFeedbackType.warning => (
        Icons.warning_amber_rounded,
        ext.warning,
      ),
    PremiumActionFeedbackType.error => (
        Icons.error_outline_rounded,
        ext.danger,
      ),
    PremiumActionFeedbackType.comingSoon => (
        Icons.hourglass_top_rounded,
        ext.accent,
      ),
    PremiumActionFeedbackType.info => (
        Icons.info_outline_rounded,
        ext.accent,
      ),
  };
}
