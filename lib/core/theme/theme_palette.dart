import 'package:flutter/material.dart';

import 'premium/premium_color_tokens.dart';

/// Ham renk paleti — yalnızca [AppThemeExtension] ve [ThemeData] oluştururken kullanılır.
/// Arayüz bileşenleri mümkün olduğunda [AppThemeExtension.of] semantic token’larını kullanmalıdır.
abstract final class ThemePalette {
  ThemePalette._();

  static const Color backgroundDark = PremiumColorTokens.obsidianElevated;
  static const Color scaffoldDark = PremiumColorTokens.obsidian;
  static const Color surfaceDark = PremiumColorTokens.midnightNavySurface;
  static const Color surfaceDarkCard = PremiumColorTokens.midnightNavy;
  static const Color surfaceDarkElevated = PremiumColorTokens.midnightNavyElevated;
  static const Color borderDark = PremiumColorTokens.midnightNavyBorder;

  static const Color antiqueGold = PremiumColorTokens.champagneGold;
  static const Color antiqueGoldWatermark = Color(0x08C9A962);
  static const Color inputBackgroundGold = PremiumColorTokens.champagneGoldLight;
  static const Color inputTextOnGold = PremiumColorTokens.textOnGold;

  static const Color brandNavy = PremiumColorTokens.midnightNavyElevated;
  static const Color brandNavyLight = PremiumColorTokens.midnightNavyBorder;
  static const Color brandGold = PremiumColorTokens.champagneGold;
  static const Color brandGoldLight = PremiumColorTokens.champagneGoldLight;
  static const Color brandWhite = Color(0xFFFAFAFA);

  static const Color primary = PremiumColorTokens.champagneGold;
  static const Color primaryDark = PremiumColorTokens.midnightNavy;
  static const Color secondary = PremiumColorTokens.champagneGold;
  static const Color accent = PremiumColorTokens.champagneGold;

  static const Color success = PremiumColorTokens.success;
  static const Color warning = PremiumColorTokens.warning;
  static const Color danger = PremiumColorTokens.danger;

  /// Bilgi SnackBar / hafif bilgi şeridi zemini (metin: [textPrimary]).
  static const Color infoSurfaceLight = Color(0xFFF0EDE7);
  static const Color infoSurfaceDark = Color(0xFF232326);
  /// Bilgi ikonları / nötr durum (açık modda soluk gri değil, sıcak nötr).
  static const Color infoIconLight = Color(0xFF69625C);
  /// Koyu yüzeyde okunur, sert beyaz değil.
  static const Color infoIconDark = Color(0xFFB0B0BA);

  /// Açık tema: hafif sıcak zemin, yüksek kontrast metin (premium + okunabilirlik).
  static const Color backgroundLight = Color(0xFFF7F5F1);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFFCFAF7);
  static const Color borderLight = Color(0xFFE4DED5);

  static const Color textPrimaryDark = Color(0xFFF5F5F5);

  /// Gövde / alt başlık — uzun kullanımda yumuşak, yeterince açık.
  static const Color textSecondaryDark = Color(0xFFCECED4);
  /// Meta / yardımcı — çamurlu gri değil, gün ışığında ekran parlaklığında okunur.
  static const Color textTertiaryDark = Color(0xFFA8A8B2);

  static const Color textPrimaryLight = Color(0xFF111111);
  static const Color textSecondaryLight = Color(0xFF3F3A36);
  static const Color textTertiaryLight = Color(0xFF5F5852);
  /// Form yer tutucu, pasif alt gezinme — üçüncülden biraz daha yumuşak, yine de gün ışığında okunur.
  static const Color textPassiveLight = Color(0xFF7A736B);

  static const Color primaryGlow = PremiumColorTokens.champagneGold;

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
