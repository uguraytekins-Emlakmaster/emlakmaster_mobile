import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/navigation/app_back_dispatcher.dart';
import 'package:emlakmaster_mobile/shared/widgets/premium_nav_glyph.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';

/// Şık, hızlı geri: hafif haptic, altın vurgu, keskin yuvarlatılmış dokunma alanı.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  /// Varsayılan: merkezi geri ([AppBackDispatcher.tryPop]).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PremiumNavGlyphButton(
      icon: Icons.arrow_back_ios_new_rounded,
      tooltip: 'Geri',
      onPressed: () async {
        if (onPressed != null) {
          AppFeedback.lightImpact();
          onPressed!();
          return;
        }
        final shell =
            context.findAncestorStateOfType<AdaptiveShellScaffoldState>();
        final handled = await AppBackDispatcher.tryPop(
          context,
          onShellBack: shell?.tryPopTabHistory,
        );
        // Asla ölü no-op: hiçbir yığın/sekme kapatılamadıysa kullanıcıyı ana
        // kabuğa götür; geri butonu hiçbir zaman sessizce tepkisiz kalmaz.
        if (!handled && context.mounted) {
          navigateToAppHome(context);
        }
      },
    );
  }
}
