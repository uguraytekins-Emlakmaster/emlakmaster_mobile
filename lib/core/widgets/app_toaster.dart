import 'dart:async';

import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
/// Profesyonel toast / SnackBar mesajları. Hata, başarı, bilgi için tutarlı stil.
class AppToaster {
  AppToaster._();

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    unawaited(AppFeedback.mediumImpact());
    final ext = AppThemeExtension.of(context);
    final (color, icon) = _styleFor(type, ext);
    final isInfo = type == ToastType.info;
    final foreground = isInfo
        ? ext.textPrimary
        : (ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87);
    final iconColor = isInfo ? ext.info : foreground;
    switch (type) {
      case ToastType.success:
        unawaited(AppFeedback.playSuccess());
        break;
      case ToastType.error:
        unawaited(AppFeedback.playError());
        break;
      case ToastType.warning:
        unawaited(AppFeedback.playWarning());
        break;
      case ToastType.info:
        break;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          side: isInfo
              ? BorderSide(color: ext.border.withValues(alpha: 0.85))
              : BorderSide.none,
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: isInfo ? ext.accent : foreground,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static (Color, IconData) _styleFor(ToastType type, AppThemeExtension ext) {
    switch (type) {
      case ToastType.success:
        return (ext.success, Icons.check_circle_rounded);
      case ToastType.error:
        return (ext.danger, Icons.error_rounded);
      case ToastType.warning:
        return (ext.warning, Icons.warning_rounded);
      case ToastType.info:
        return (ext.infoSurface, Icons.info_rounded);
    }
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.error, duration: const Duration(seconds: 4));

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message);
}

enum ToastType { success, error, warning, info }
