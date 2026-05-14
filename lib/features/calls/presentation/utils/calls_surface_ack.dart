import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Kısa, sakin onay — SnackBar altyapısı; yoğun snackbar hissi vermeden güven verir.
void showCallsSurfaceAck(BuildContext context, String message) {
  final ext = AppThemeExtension.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ext.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
      ),
      duration: const Duration(milliseconds: 1500),
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
