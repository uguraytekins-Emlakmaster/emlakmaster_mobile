import 'package:flutter/material.dart';

/// Ham renk paleti — yalnızca [AppThemeExtension] ve [ThemeData] oluştururken kullanılır.
/// Arayüz bileşenleri mümkün olduğunda [AppThemeExtension.of] semantic token’larını kullanmalıdır.
abstract final class ThemePalette {
  ThemePalette._();

  static const Color backgroundDark = Color(0xFF0A0A0C);
  static const Color scaffoldDark = Color(0xFF050506);
  static const Color surfaceDark = Color(0xFF141416);
  static const Color surfaceDarkCard = Color(0xFF121214);
  static const Color surfaceDarkElevated = Color(0xFF1C1C1F);
  static const Color borderDark = Color(0xFF2E2E32);

  static const Color antiqueGold = Color(0xFFBFA071);
  static const Color antiqueGoldWatermark = Color(0x08BFA071);
  static const Color inputBackgroundGold = Color(0xFFD4C4A8);
  static const Color inputTextOnGold = Color(0xFF1A1A1A);

  static const Color brandNavy = Color(0xFF2A2A2E);
  static const Color brandNavyLight = Color(0xFF3A3A40);
  static const Color brandGold = Color(0xFFBFA071);
  static const Color brandGoldLight = Color(0xFFD4C4A8);
  static const Color brandWhite = Color(0xFFFAFAFA);

  static const Color primary = Color(0xFFBFA071);
  static const Color primaryDark = Color(0xFF121214);
  static const Color secondary = Color(0xFFBFA071);
  static const Color accent = Color(0xFFBFA071);

  static const Color success = Color(0xFF1B5E20);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF8E8E93);

  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFFAFAFA);
  static const Color borderLight = Color(0xFFE5E5E7);

  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  /// Okunabilir ikincil metin (koyu tema; WCAG için biraz açıldı).
  static const Color textSecondaryDark = Color(0xFFC8C8CE);
  static const Color textTertiaryDark = Color(0xFF9A9AA3);

  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF6B6B70);
  static const Color textTertiaryLight = Color(0xFF8E8E93);

  static const Color primaryGlow = Color(0xFFBFA071);

  static List<Color> get gradientPrimary => [backgroundDark, surfaceDark];
  static List<Color> get gradientCardBorder => [
        antiqueGold.withValues(alpha: 0.35),
        antiqueGold.withValues(alpha: 0.1),
      ];

  static Color get shimmerBaseDark => surfaceDarkElevated;
  static Color get shimmerHighlightDark => surfaceDark.withValues(alpha: 0.5);
  static const Color shimmerBaseLight = borderLight;
  static const Color shimmerHighlightLight = surfaceLight;
}
