import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Şık, hızlı geri: hafif haptic, altın vurgu, yuvarlatılmış dokunma alanı.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  /// Varsayılan: [context.pop] (yığın varsa).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    // Single [IconButton] tooltip (under route / Navigator Overlay). Avoid wrapping
    // with an extra [Tooltip] to prevent duplicate RawTooltip layers.
    return IconButton(
      tooltip: 'Geri',
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
      padding: const EdgeInsets.only(left: 10),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      style: IconButton.styleFrom(
        foregroundColor: ext.accent,
        backgroundColor: ext.accent.withValues(alpha: 0.09),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        if (onPressed != null) {
          onPressed!();
          return;
        }
        if (context.canPop()) {
          context.pop();
        }
      },
    );
  }
}
