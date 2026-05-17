import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/navigation/app_back_dispatcher.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

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
        if (onPressed != null) {
          AppFeedback.lightImpact();
          onPressed!();
          return;
        }
        final shell = context.findAncestorStateOfType<AdaptiveShellScaffoldState>();
        AppBackDispatcher.tryPop(
          context,
          onShellBack: shell?.tryPopTabHistory,
        );
      },
    );
  }
}
