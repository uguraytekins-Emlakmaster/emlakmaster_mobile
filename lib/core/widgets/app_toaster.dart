import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    HapticFeedback.mediumImpact();
    final (color, icon) = _styleFor(type);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static (Color, IconData) _styleFor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return (DesignTokens.success, Icons.check_circle_rounded);
      case ToastType.error:
        return (DesignTokens.danger, Icons.error_rounded);
      case ToastType.warning:
        return (DesignTokens.warning, Icons.warning_rounded);
      case ToastType.info:
        return (DesignTokens.info, Icons.info_rounded);
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
