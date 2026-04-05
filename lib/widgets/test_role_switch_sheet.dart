import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debug / test: tüm [AppRole] listesi — küçük ekranda taşmayı önlemek için kaydırılabilir.
void showTestRoleSwitchSheet(
  BuildContext context,
  WidgetRef ref,
  AppRole? currentOverride,
) {
  final theme = Theme.of(context);
  showPremiumModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final padding = MediaQuery.paddingOf(ctx);
      final maxH = MediaQuery.sizeOf(ctx).height - padding.top - padding.bottom;
      final ext = AppThemeExtension.of(ctx);
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH * 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  padding: EdgeInsets.only(
                    bottom: padding.bottom + DesignTokens.space4,
                  ),
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
          ),
        ),
      );
    },
  );
}
