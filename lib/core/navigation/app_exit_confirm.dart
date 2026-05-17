import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kök sekmede Android geri — uygulamadan çıkış onayı.
Future<bool> showAppExitConfirmation(BuildContext context) async {
  final result = await showPremiumScrollableBottomSheet<bool>(
    context: context,
    maxHeightFactor: 0.38,
    builder: (ctx) {
      final ext = AppThemeExtension.of(ctx);
      return PremiumScrollableBottomSheetShell(
        title: 'Uygulamadan çıkılsın mı?',
        subtitle: 'Geri tuşuna tekrar basarak çıkabilirsiniz.',
        bottomActions: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Kal'),
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: ext.accent,
                  foregroundColor: ext.onBrand,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Çık'),
              ),
            ),
          ],
        ),
        child: const SizedBox.shrink(),
      );
    },
  );
  return result == true;
}

Future<void> maybeExitApplication(BuildContext context) async {
  final ok = await showAppExitConfirmation(context);
  if (ok) {
    await SystemNavigator.pop();
  }
}
