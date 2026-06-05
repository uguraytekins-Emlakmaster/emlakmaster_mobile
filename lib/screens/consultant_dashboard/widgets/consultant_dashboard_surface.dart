import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_glass_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_shadow_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Layered glass executive surface — shadows, edge light, ambient glow.
class ConsultantDashboardExecutiveSurface extends StatelessWidget {
  const ConsultantDashboardExecutiveSurface({
    super.key,
    required this.child,
    this.goldBorder = false,
    this.goldRail = false,
    this.padding,
    this.radius = DesignTokens.radiusLg,
    this.onTap,
    this.ambientGlow = true,
    this.ambientStrength = 1.0,
  });

  final Widget child;
  final bool goldBorder;
  final bool goldRail;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final bool ambientGlow;
  final double ambientStrength;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final glowAlpha = 0.09 * ambientStrength.clamp(0.5, 1.5);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: PremiumShadowTokens.executiveCard(
          shadowColor: ext.shadowColor,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            if (ambientGlow)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.65),
                      radius: 1.35,
                      colors: [
                        premium.champagneGold.withValues(alpha: glowAlpha),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            if (ambientStrength > 1)
              Positioned(
                right: -20,
                bottom: -30,
                child: IgnorePointer(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: PremiumShadowTokens.ambientGlow(
                        color: premium.champagneGold,
                      ),
                    ),
                  ),
                ),
              ),
            DecoratedBox(
              decoration: PremiumGlassTokens.surface(
                isDark: premium.isDark,
                goldBorder: goldBorder,
                radius: radius,
              ),
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ),
            Positioned(
              top: goldRail ? 3 : 0,
              left: 14,
              right: 14,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      premium.champagneGold.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (goldRail)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: PremiumGlassTokens.goldAccentGradient(),
                    boxShadow: PremiumShadowTokens.goldGlow(),
                  ),
                ),
              ),
            if (goldBorder || goldRail)
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        premium.champagneGold.withValues(alpha: 0.5),
                        premium.champagneGold.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: surface,
        ),
      );
    }

    return surface;
  }
}

/// Operational tier — standard vs revenue cockpit depth.
enum ConsultantDashboardOpsTier {
  standard,
  performance,
  revenue,
}

/// Operational card chrome — matches cockpit premium language.
class ConsultantDashboardOpsShell extends StatelessWidget {
  const ConsultantDashboardOpsShell({
    super.key,
    required this.child,
    this.tier = ConsultantDashboardOpsTier.standard,
    this.emphasized = false,
  });

  final Widget child;
  final ConsultantDashboardOpsTier tier;
  final bool emphasized;

  ConsultantDashboardOpsTier get _effectiveTier =>
      emphasized ? ConsultantDashboardOpsTier.performance : tier;

  bool get _emphasized =>
      _effectiveTier == ConsultantDashboardOpsTier.performance;

  bool get _revenue => _effectiveTier == ConsultantDashboardOpsTier.revenue;

  @override
  Widget build(BuildContext context) {
    final gold = _emphasized || _revenue;
    return ConsultantDashboardExecutiveSurface(
      goldBorder: gold,
      goldRail: _emphasized,
      ambientStrength: _revenue ? 1.35 : (_emphasized ? 1.15 : 0.85),
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: _revenue ? DesignTokens.space4 : DesignTokens.space3,
      ),
      child: child,
    );
  }
}
