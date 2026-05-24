import 'dart:ui';

import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_shadow_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Phase 2 — glass navigation rail for wide layouts (admin / consultant / client).
class PremiumNavigationRail extends StatelessWidget {
  const PremiumNavigationRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AdaptiveNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const double width = 88;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: premium.glassBlur * 0.65,
          sigmaY: premium.glassBlur * 0.65,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: premium.navDockSurface.withValues(alpha: 0.88),
            border: Border(
              right: BorderSide(
                color: premium.glassBorder.withValues(alpha: 0.28),
              ),
            ),
            boxShadow: PremiumShadowTokens.cardSubtle(),
          ),
          child: NavigationRail(
            selectedIndex: selectedIndex.clamp(0, items.length - 1),
            onDestinationSelected: onDestinationSelected,
            backgroundColor: Colors.transparent,
            indicatorColor: premium.champagneGold.withValues(alpha: 0.16),
            selectedIconTheme: IconThemeData(color: premium.champagneGold, size: 24),
            unselectedIconTheme: IconThemeData(
              color: ext.textPassive,
              size: 22,
            ),
            selectedLabelTextStyle: TextStyle(
              color: premium.champagneGold,
              fontWeight: FontWeight.w700,
              fontSize: DesignTokens.fontSizeXs,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: ext.textTertiary,
              fontWeight: FontWeight.w500,
              fontSize: DesignTokens.fontSizeXs,
            ),
            labelType: NavigationRailLabelType.all,
            minWidth: width,
            destinations: items
                .map(
                  (e) => NavigationRailDestination(
                    icon: Icon(e.icon),
                    selectedIcon: Icon(e.icon),
                    label: Text(e.label),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
