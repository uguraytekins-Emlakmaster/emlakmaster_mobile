import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_glass_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';

/// Phase 1 — unified loading / empty / error / offline / skeleton states.
class PremiumStateViews {
  PremiumStateViews._();

  static Widget loading({
  required BuildContext context,
  String? message,
}) {
    final ext = AppThemeExtension.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: ext.accent,
            strokeWidth: 2.5,
          ),
          if (message != null) ...[
            const SizedBox(height: DesignTokens.space4),
            Text(
              message,
              style: TextStyle(color: ext.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static Widget empty({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      premiumVisual: true,
      grouped: true,
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static Widget error({
    required BuildContext context,
    required String title,
    String? subtitle,
    VoidCallback? onRetry,
  }) {
    final ext = AppThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: ext.danger),
            const SizedBox(height: DesignTokens.space4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: DesignTokens.fontSizeLg,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignTokens.space2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: ext.textSecondary, height: 1.45),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: DesignTokens.space5),
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, color: ext.accent),
                label: Text('Yeniden dene',
                    style: TextStyle(color: ext.accent)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget offlineBanner({
    required BuildContext context,
    required VoidCallback? onTap,
    String message = 'İnternet yok. Veriler önbellekten gösteriliyor.',
  }) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ext.warning.withValues(alpha: 0.12),
            border: Border(
              bottom: BorderSide(color: ext.warning.withValues(alpha: 0.35)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space4,
              vertical: DesignTokens.space2,
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, size: 16, color: ext.warning),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: ext.warning,
                      fontSize: DesignTokens.fontSizeSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.info_outline_rounded,
                    size: 16, color: premium.champagneGoldMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget skeletonList({
    required BuildContext context,
    int count = 4,
    double itemHeight = 72,
  }) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.space3),
      itemBuilder: (_, __) => SkeletonLoader(
        height: itemHeight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
      ),
    );
  }
}

/// Sheet handle — Figma gold accent bar.
class PremiumSheetHandle extends StatelessWidget {
  const PremiumSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: DesignTokens.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          color: premium.champagneGold.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Dialog shell — glass card on obsidian scrim.
class PremiumDialogShell extends StatelessWidget {
  const PremiumDialogShell({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(DesignTokens.space6),
      child: DecoratedBox(
        decoration: PremiumGlassTokens.surface(
          isDark: premium.isDark,
          radius: DesignTokens.radiusLg,
          goldBorder: true,
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: DesignTokens.space3),
              content,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.space4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
