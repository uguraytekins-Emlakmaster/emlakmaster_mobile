import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debug / test: tüm [AppRole] listesi — [DraggableScrollableSheet] + güvenli yükseklik (taşma yok).
void showTestRoleSwitchSheet(
  BuildContext context,
  WidgetRef ref,
  AppRole? currentOverride,
) {
  final theme = Theme.of(context);
  showPremiumDraggableBottomSheet<void>(
    context: context,
    initialChildSize: 0.72,
    maxChildSize: 0.88,
    builder: (ctx, scrollController) {
      final ext = AppThemeExtension.of(ctx);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumBottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space4,
              0,
              DesignTokens.space4,
              DesignTokens.space2,
            ),
            child: Text(
              'Test için rol seç (sadece görünüm)',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: DesignTokens.space4),
              children: [
                for (final r in AppRole.values)
                  ListTile(
                    title: Text(
                      r.label,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    trailing: currentOverride == r
                        ? Icon(Icons.check_rounded, color: ext.accent)
                        : null,
                    onTap: () {
                      ref.read(overrideRoleProvider.notifier).state =
                          currentOverride == r ? null : r;
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
