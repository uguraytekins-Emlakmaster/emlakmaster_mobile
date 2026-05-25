import 'dart:ui';

import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_color_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_glass_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_shadow_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Layout metrics for the floating dock — scales with text scale & width.
@immutable
class PremiumBottomNavMetrics {
  const PremiumBottomNavMetrics({
    required this.contentHeight,
    required this.iconSize,
    required this.iconSizeSelected,
    required this.labelSize,
    required this.labelSizeSelected,
    required this.itemVerticalPadding,
    required this.labelGap,
    required this.blurSigma,
  });

  final double contentHeight;
  final double iconSize;
  final double iconSizeSelected;
  final double labelSize;
  final double labelSizeSelected;
  final double itemVerticalPadding;
  final double labelGap;
  final double blurSigma;

  static PremiumBottomNavMetrics of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = mq.textScaler.scale(1.0).clamp(1.0, 1.35);
    final width = mq.size.width;
    final compact = width < 360 || scale > 1.12;

    final baseContent = compact ? 56.0 : 60.0;
    final contentHeight = (baseContent * scale).clamp(56.0, 68.0);

    return PremiumBottomNavMetrics(
      contentHeight: contentHeight,
      iconSize: compact ? 19 : 20,
      iconSizeSelected: compact ? 21 : 22,
      labelSize: compact ? 8.5 : 9,
      labelSizeSelected: compact ? 9 : 9.5,
      itemVerticalPadding: compact ? 3 : 4,
      labelGap: compact ? 2 : 3,
      blurSigma: compact ? 22 : 28,
    );
  }

  /// Total vertical space the shell should reserve (dock + safe area + float margin).
  static double reservedHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final metrics = of(context);
    const outerBottom = 8.0;
    const topEdge = 1.0;
    return metrics.contentHeight + topEdge + mq.padding.bottom + outerBottom + 6;
  }
}

/// Yüzen premium alt gezinme — luxury glass dock + champagne glow active state.
class PremiumBottomNavDock extends StatelessWidget {
  const PremiumBottomNavDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.centerItemIndex,
    this.onCenterTap,
    this.centerIcon = Icons.add_rounded,
    this.centerLabel,
  });

  final List<AdaptiveNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int? centerItemIndex;
  final VoidCallback? onCenterTap;
  final IconData centerIcon;
  final String? centerLabel;

  static const double centerButtonSize = 50;

  /// @deprecated Use [PremiumBottomNavMetrics.reservedHeight].
  static double reservedHeight(BuildContext context) =>
      PremiumBottomNavMetrics.reservedHeight(context);

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final metrics = PremiumBottomNavMetrics.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasCenter = centerItemIndex != null && onCenterTap != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            ...PremiumShadowTokens.dockLuxury(shadowColor: ext.shadowColor),
            ...PremiumShadowTokens.ambientGlow(color: premium.champagneGold),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: metrics.blurSigma,
              sigmaY: metrics.blurSigma,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    premium.navDockSurface.withValues(alpha: 0.96),
                    premium.navDockSurface.withValues(alpha: 0.78),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  width: 1.15,
                  color: premium.champagneGold.withValues(alpha: 0.42),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 1,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          premium.champagneGold.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: PremiumShadowTokens.goldGlow(),
                    ),
                  ),
                  SizedBox(
                    height: metrics.contentHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (hasCenter && i == centerItemIndex)
                            _CenterNavSlot(
                              icon: centerIcon,
                              label: centerLabel,
                              onTap: onCenterTap!,
                              ext: ext,
                              premium: premium,
                              metrics: metrics,
                            )
                          else
                            Expanded(
                              child: _DockNavItem(
                                item: items[i],
                                selected: selectedIndex == i,
                                onTap: () => onTap(i),
                                ext: ext,
                                premium: premium,
                                metrics: metrics,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockNavItem extends StatelessWidget {
  const _DockNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.ext,
    required this.premium,
    required this.metrics,
  });

  final AdaptiveNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final AppThemeExtension ext;
  final PremiumThemeExtension premium;
  final PremiumBottomNavMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = ext.textPassive.withValues(alpha: 0.72);
    const activeColor = PremiumColorTokens.champagneGoldLight;
    final iconSize =
        selected ? metrics.iconSizeSelected : metrics.iconSize;
    final labelSize =
        selected ? metrics.labelSizeSelected : metrics.labelSize;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 3,
            vertical: metrics.itemVerticalPadding,
          ),
          child: DecoratedBox(
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        premium.champagneGold.withValues(alpha: 0.28),
                        premium.champagneGold.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: premium.champagneGold.withValues(alpha: 0.52),
                    ),
                    boxShadow: PremiumShadowTokens.navSelectedGlow(),
                  )
                : const BoxDecoration(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: selected
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                premium.champagneGold.withValues(alpha: 0.24),
                                premium.champagneGold.withValues(alpha: 0.06),
                              ],
                            ),
                            border: Border.all(
                              color:
                                  premium.champagneGold.withValues(alpha: 0.45),
                            ),
                            boxShadow: PremiumShadowTokens.goldGlow(),
                          )
                        : const BoxDecoration(),
                    child: Padding(
                      padding: EdgeInsets.all(selected ? 5 : 3),
                      child: Icon(
                        item.icon,
                        size: iconSize,
                        color: selected ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                  SizedBox(height: metrics.labelGap),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: selected ? activeColor : inactiveColor,
                        fontSize: labelSize,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                        letterSpacing: selected ? 0.25 : 0,
                        height: 1,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterNavSlot extends StatelessWidget {
  const _CenterNavSlot({
    required this.icon,
    required this.onTap,
    required this.ext,
    required this.premium,
    required this.metrics,
    this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final AppThemeExtension ext;
  final PremiumThemeExtension premium;
  final PremiumBottomNavMetrics metrics;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: PremiumGlassTokens.goldAccentGradient(),
                boxShadow: [
                  ...PremiumShadowTokens.goldGlow(),
                  BoxShadow(
                    color: premium.champagneGold.withValues(alpha: 0.38),
                    blurRadius: 18,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: PremiumBottomNavDock.centerButtonSize,
                    height: PremiumBottomNavDock.centerButtonSize,
                    child: Icon(icon, color: ext.onBrand, size: 24),
                  ),
                ),
              ),
            ),
            if (label != null) ...[
              SizedBox(height: metrics.labelGap),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label!,
                  style: TextStyle(
                    color: PremiumColorTokens.champagneGoldLight,
                    fontSize: metrics.labelSizeSelected,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
