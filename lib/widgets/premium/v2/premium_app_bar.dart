import 'package:emlakmaster_mobile/core/navigation/app_back_dispatcher.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_glass_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Phase 1 — executive top bar with optional glass blur.
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.glass = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final bool glass;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 56 : 68);

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);

    Widget bar = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space4,
          DesignTokens.space2,
          DesignTokens.space4,
          DesignTokens.space2,
        ),
        child: Row(
          children: [
            leading ??
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: ext.accent, size: 20),
                  onPressed: () => AppBackDispatcher.tryPop(context),
                ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ext.textSecondary,
                          ),
                    ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );

    if (glass) {
      bar = PremiumGlassTokens.blur(
        sigma: premium.glassBlur * 0.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: premium.glassSurface.withValues(alpha: 0.72),
            border: Border(
              bottom: BorderSide(color: premium.glassBorder.withValues(alpha: 0.35)),
            ),
          ),
          child: bar,
        ),
      );
    }

    return Material(
      color: ext.background,
      child: bar,
    );
  }
}
