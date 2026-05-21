import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/app_back_dispatcher.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Kabuk içi Günüm / Komuta Merkezi veya [AppRouter.routeHome].
void navigateToAppHome(BuildContext context) {
  AppFeedback.lightImpact();
  final shell = ConsultantShellNav.maybeOf(context);
  if (shell != null) {
    ConsultantShellNav.goToHomeTab(context);
    return;
  }
  if (context.mounted) {
    context.go(AppRouter.routeHome);
  }
}

/// Ana sayfaya — kompakt altın ikon.
class PremiumHomeButton extends StatelessWidget {
  const PremiumHomeButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return IconButton(
      tooltip: 'Ana sayfa',
      onPressed: () => navigateToAppHome(context),
      icon: Icon(
        Icons.home_rounded,
        size: compact ? 20 : 22,
        color: ext.accent,
      ),
      style: IconButton.styleFrom(
        foregroundColor: ext.accent,
        backgroundColor: ext.accent.withValues(alpha: 0.09),
        minimumSize: Size(compact ? 40 : 44, compact ? 40 : 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
      ),
    );
  }
}

/// Geri (varsa) + ana sayfa — tüm tam sayfa rotalar için.
class PremiumNavLeading extends StatelessWidget {
  const PremiumNavLeading({
    super.key,
    this.showHomeWhenCanPop = true,
  });

  /// Geri varken de ana sayfa kısayolu göster.
  final bool showHomeWhenCanPop;

  @override
  Widget build(BuildContext context) {
    final canPop = AppBackDispatcher.canPopRoute(context);
    if (!canPop) {
      return const PremiumHomeButton(compact: true);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBackButton(),
        if (showHomeWhenCanPop) const PremiumHomeButton(compact: true),
      ],
    );
  }

  static double leadingWidth(BuildContext context) {
    if (!AppBackDispatcher.canPopRoute(context)) return 52;
    return 96;
  }
}
