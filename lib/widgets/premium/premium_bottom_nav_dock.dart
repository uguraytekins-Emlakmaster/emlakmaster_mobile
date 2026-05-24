import 'dart:ui';

import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_glass_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_motion_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_shadow_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Yüzen premium alt gezinme — glass blur + champagne gold active state.
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

  static const double dockHeight = 64;
  static const double centerButtonSize = 52;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasCenter = centerItemIndex != null && onCenterTap != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius3xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: premium.glassBlur,
            sigmaY: premium.glassBlur,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: premium.navDockSurface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(DesignTokens.radius3xl),
              border: Border.all(
                color: premium.glassBorder.withValues(alpha: 0.35),
              ),
              boxShadow: PremiumShadowTokens.dock(shadowColor: ext.shadowColor),
            ),
            child: SizedBox(
              height: dockHeight,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (hasCenter && i == centerItemIndex)
                      _CenterNavSlot(
                        icon: centerIcon,
                        label: centerLabel,
                        onTap: onCenterTap!,
                        ext: ext,
                        premium: premium,
                      )
                    else
                      Expanded(
                        child: _DockNavItem(
                          item: items[i],
                          selected: selectedIndex == i,
                          onTap: () => onTap(i),
                          ext: ext,
                          premium: premium,
                        ),
                      ),
                  ],
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
  });

  final AdaptiveNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final AppThemeExtension ext;
  final PremiumThemeExtension premium;

  @override
  Widget build(BuildContext context) {
    final color = selected ? premium.champagneGold : ext.textPassive;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        child: AnimatedContainer(
          duration: PremiumMotionTokens.fast,
          curve: PremiumMotionTokens.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
                  color: premium.champagneGold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: premium.champagneGold.withValues(alpha: 0.28),
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: PremiumGlassTokens.goldAccentGradient(),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
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
    this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final AppThemeExtension ext;
  final PremiumThemeExtension premium;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: PremiumGlassTokens.goldAccentGradient(),
                boxShadow: PremiumShadowTokens.goldGlow(),
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
                    child: Icon(icon, color: ext.onBrand, size: 26),
                  ),
                ),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(
                label!,
                style: TextStyle(
                  color: premium.champagneGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
