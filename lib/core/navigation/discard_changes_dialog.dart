import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
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
      final l10n = AppLocalizations.of(ctx);
      return PremiumScrollableBottomSheetShell(
        title: l10n.t('discard_changes_title'),
        subtitle: l10n.t('discard_changes_subtitle'),
        bottomActions: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: ext.textPrimary,
                ),
                child: Text(l10n.t('action_continue')),
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
                  l10n.t('action_exit'),
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
