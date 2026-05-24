import 'package:flutter/material.dart';

import 'premium_color_tokens.dart';
import 'premium_glass_tokens.dart';

/// Premium visual layer — glass, gold glow, executive surfaces.
/// [AppThemeExtension] semantic renklerle birlikte kullanılır.
@immutable
class PremiumThemeExtension extends ThemeExtension<PremiumThemeExtension> {
  const PremiumThemeExtension({
    required this.glassSurface,
    required this.glassBorder,
    required this.glassBlur,
    required this.navDockSurface,
    required this.champagneGold,
    required this.champagneGoldMuted,
    required this.heroGradient,
    required this.isDark,
  });

  final Color glassSurface;
  final Color glassBorder;
  final double glassBlur;
  final Color navDockSurface;
  final Color champagneGold;
  final Color champagneGoldMuted;
  final LinearGradient heroGradient;
  final bool isDark;

  static PremiumThemeExtension dark() {
    return const PremiumThemeExtension(
      glassSurface: PremiumColorTokens.glassFill,
      glassBorder: PremiumColorTokens.glassBorder,
      glassBlur: PremiumGlassTokens.defaultBlur,
      navDockSurface: PremiumColorTokens.midnightNavySurface,
      champagneGold: PremiumColorTokens.champagneGold,
      champagneGoldMuted: PremiumColorTokens.champagneGoldMuted,
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          PremiumColorTokens.midnightNavy,
          PremiumColorTokens.obsidian,
        ],
      ),
      isDark: true,
    );
  }

  static PremiumThemeExtension light() {
    return PremiumThemeExtension(
      glassSurface: PremiumColorTokens.paperSurface.withValues(alpha: 0.92),
      glassBorder: PremiumColorTokens.champagneGold.withValues(alpha: 0.22),
      glassBlur: PremiumGlassTokens.defaultBlur,
      navDockSurface: PremiumColorTokens.paperSurface,
      champagneGold: PremiumColorTokens.champagneGold,
      champagneGoldMuted: PremiumColorTokens.champagneGoldMuted,
      heroGradient: PremiumGlassTokens.heroGradient(isDark: false),
      isDark: false,
    );
  }

  static PremiumThemeExtension of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PremiumThemeExtension>() ??
        (theme.brightness == Brightness.dark
            ? PremiumThemeExtension.dark()
            : PremiumThemeExtension.light());
  }

  @override
  PremiumThemeExtension copyWith({
    Color? glassSurface,
    Color? glassBorder,
    double? glassBlur,
    Color? navDockSurface,
    Color? champagneGold,
    Color? champagneGoldMuted,
    LinearGradient? heroGradient,
    bool? isDark,
  }) {
    return PremiumThemeExtension(
      glassSurface: glassSurface ?? this.glassSurface,
      glassBorder: glassBorder ?? this.glassBorder,
      glassBlur: glassBlur ?? this.glassBlur,
      navDockSurface: navDockSurface ?? this.navDockSurface,
      champagneGold: champagneGold ?? this.champagneGold,
      champagneGoldMuted: champagneGoldMuted ?? this.champagneGoldMuted,
      heroGradient: heroGradient ?? this.heroGradient,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  PremiumThemeExtension lerp(
    ThemeExtension<PremiumThemeExtension>? other,
    double t,
  ) {
    if (other is! PremiumThemeExtension) return this;
    return PremiumThemeExtension(
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBlur: glassBlur + (other.glassBlur - glassBlur) * t,
      navDockSurface: Color.lerp(navDockSurface, other.navDockSurface, t)!,
      champagneGold: Color.lerp(champagneGold, other.champagneGold, t)!,
      champagneGoldMuted:
          Color.lerp(champagneGoldMuted, other.champagneGoldMuted, t)!,
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
