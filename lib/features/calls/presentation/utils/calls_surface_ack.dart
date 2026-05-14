import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Kısa, sakin onay — yüzen SnackBar; büyük gürültü yaratmadan güven verir.
void showCallsSurfaceAck(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration duration = const Duration(milliseconds: 1300),
}) {
  final ext = AppThemeExtension.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: ext.textPrimary,
        fontWeight: FontWeight.w500,
        height: 1.25,
      );
  messenger.showSnackBar(
    SnackBar(
      content: icon == null
          ? Text(message, style: textStyle)
          : Row(
              children: [
                Icon(icon, size: 20, color: ext.success),
                const SizedBox(width: DesignTokens.space2 + 2),
                Expanded(child: Text(message, style: textStyle)),
              ],
            ),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        0,
        DesignTokens.space4,
        72,
      ),
      elevation: 0,
      backgroundColor: ext.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        side: BorderSide(color: ext.border.withValues(alpha: 0.42)),
      ),
    ),
  );
}
