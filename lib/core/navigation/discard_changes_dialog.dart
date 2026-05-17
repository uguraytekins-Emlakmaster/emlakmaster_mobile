import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';

/// Premium “çıkmak istiyor musunuz?” onayı.
Future<bool?> showDiscardChangesDialog(BuildContext context) {
  return showPremiumScrollableBottomSheet<bool>(
    context: context,
    maxHeightFactor: 0.42,
    builder: (ctx) {
      final ext = AppThemeExtension.of(ctx);
      return PremiumScrollableBottomSheetShell(
        title: 'Çıkmak istiyor musunuz?',
        subtitle: 'Kaydedilmemiş değişiklikler kaybolacak.',
        bottomActions: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: ext.textPrimary,
                ),
                child: const Text('Devam et'),
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: ext.danger,
                  foregroundColor: ext.onBrand,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(
                  'Çık',
                  style: AppTypography.bodyStrong(ctx).copyWith(
                    color: ext.onBrand,
                  ),
                ),
              ),
            ),
          ],
        ),
        child: const SizedBox.shrink(),
      );
    },
  );
}
