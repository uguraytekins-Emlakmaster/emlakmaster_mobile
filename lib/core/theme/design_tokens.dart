import 'package:flutter/material.dart';

/// EmlakMaster design tokens — Wealth Tech / Gold Century referansı.
/// Koyu zemin (#1E1E1E), Antique Gold (#BFA071) aksan, neomorphic, minimalist.
abstract final class DesignTokens {
  DesignTokens._();

  // ---------- Wealth Tech palet (referans: Gold Century)
  /// Ana arka plan — derin koyu gri.
  static const Color backgroundDark = Color(0xFF1E1E1E);
  /// Scaffold / tam sayfa arka plan (koyu).
  static const Color scaffoldDark = Color(0xFF0D1117);
  /// Kart / yüzey — hafif açık.
  static const Color surfaceDark = Color(0xFF252525);
  /// Kart yüzeyi (dropdown, liste öğesi).
  static const Color surfaceDarkCard = Color(0xFF161B22);
  static const Color surfaceDarkElevated = Color(0xFF2D2D2D);
  static const Color borderDark = Color(0xFF3A3A3A);

  /// Birincil aksan: Antique Gold (başlıklar, CTA, sayılar, aktif durum).
  static const Color antiqueGold = Color(0xFFBFA071);
  /// Filigran / mühür için çok şeffaf (~0.03).
  static const Color antiqueGoldWatermark = Color(0x08BFA071);
  /// Input / pill arka planı — krem-altın.
  static const Color inputBackgroundGold = Color(0xFFD4C4A8);
  static const Color inputTextOnGold = Color(0xFF1A1A1A);

  // ---------- Brand (Rainbow Gayrimenkul — legacy uyum)
  static const Color brandNavy = Color(0xFF1A237E);
  static const Color brandNavyLight = Color(0xFF283593);
  static const Color brandGold = Color(0xFFBFA071);
  static const Color brandGoldLight = Color(0xFFD4C4A8);
  static const Color brandWhite = Color(0xFFFAFAFA);

  // ---------- Semantic (tema ile uyumlu)
  static const Color primary = Color(0xFFBFA071);
  static const Color primaryDark = Color(0xFF0D1542);
  static const Color secondary = Color(0xFFBFA071);
  static const Color accent = Color(0xFFBFA071);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFFAFAFA);
  static const Color borderLight = Color(0xFFE5E5E7);

  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB8B8B8);
  static const Color textTertiaryDark = Color(0xFF8A8A8A);

  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF6B6B70);
  static const Color textTertiaryLight = Color(0xFF8E8E93);

  // ---------- Spacing scale (4px base)
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  // Tercihli ana boşluklar (4-8-12-16-24-32-48-64); space5/space10 legacy kullanımlar için.
  static const double space5 = 20; // legacy – mümkün olduğunda space4/space6 tercih et
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40; // legacy
  static const double space12 = 48;
  static const double space16 = 64;

  // ---------- Radius scale
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radius3xl = 28;
  static const double radiusFull = 9999;

  // ---------- Typography scale (font sizes)
  static const double fontSizeXs = 10;
  static const double fontSizeSm = 12;
  static const double fontSizeBase = 14;
  static const double fontSizeMd = 16;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 20;
  static const double fontSize2xl = 24;
  static const double fontSize3xl = 30;

  // ---------- Icon scale
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  // ---------- Typography (Wealth Tech: temiz sans, hiyerarşi)
  static TextStyle get textDisplayTitleDark => const TextStyle(
        color: textPrimaryDark,
        fontSize: fontSize3xl,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get textPageTitleDark => const TextStyle(
        color: antiqueGold,
        fontSize: fontSize2xl,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle get textSectionTitleDark => const TextStyle(
        color: textSecondaryDark,
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get textCardTitleDark => const TextStyle(
        color: textPrimaryDark,
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get textBodyDark => const TextStyle(
        color: textSecondaryDark,
        fontSize: fontSizeBase,
        height: 1.45,
      );

  static TextStyle get textCaptionDark => const TextStyle(
        color: textTertiaryDark,
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get textMetricDark => const TextStyle(
        color: antiqueGold,
        fontSize: fontSize2xl,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  // ---------- Elevation / shadow (conceptual; use Material elevation or custom)
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation3 = 4;
  static const double elevation4 = 8;

  // ---------- Layout (minimalist — cömert boşluk)
  static const double contentPaddingHorizontal = 24;
  static const double contentPaddingVertical = 20;
  static const double screenEdgePadding = 20;

  // ---------- Breakpoints (adaptive: Web/Desktop vs Mobile)
  /// Geniş ekran: sidebar navigation. Dar ekran: bottom nav.
  static const double breakpointWide = 600;

  // ---------- Animation
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 280);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // ---------- Champion / Premium
  static const Color primaryGlow = Color(0xFFBFA071);
  static List<Color> get gradientPrimary => [backgroundDark, surfaceDark];
  static List<Color> get gradientCardBorder =>
      [antiqueGold.withValues(alpha: 0.35), antiqueGold.withValues(alpha: 0.1)];
  static BoxDecoration cardChampion({
    bool withGlow = false,
    Color? borderColor,
  }) =>
      BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(
          color: borderColor ?? borderDark,
        ),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: antiqueGold.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      );

  // ---------- Neomorphic (Wealth Tech / Executive Edge)
  /// Çok hafif emboss: metallic brass hissi.
  static List<BoxShadow> get neomorphicEmbossDark => [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.03),
          offset: const Offset(-1.5, -1.5),
          blurRadius: 3,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          offset: const Offset(1.5, 1.5),
          blurRadius: 4,
        ),
      ];
  static List<BoxShadow> neomorphicGlowAntiqueGold({double intensity = 0.2}) => [
        BoxShadow(
          color: antiqueGold.withValues(alpha: intensity),
          blurRadius: 12,
        ),
      ];
  static BoxDecoration cardNeomorphic({
    bool hoverOrActive = false,
    Color? surfaceColor,
  }) =>
      BoxDecoration(
        color: surfaceColor ?? surfaceDark,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(
          color: hoverOrActive ? antiqueGold.withValues(alpha: 0.35) : borderDark.withValues(alpha: 0.8),
          width: 0.8,
        ),
        boxShadow: [
          ...neomorphicEmbossDark,
          if (hoverOrActive) ...neomorphicGlowAntiqueGold(intensity: 0.15),
        ],
      );

  /// Dashboard / War Room kartları — tek tip köşe + gölge (Rainbow Gayrimenkul premium).
  static BoxDecoration dashboardCardDecoration({
    bool highlight = false,
    Color? surfaceColor,
  }) =>
      BoxDecoration(
        color: surfaceColor ?? surfaceDark,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(
          color: highlight ? antiqueGold.withValues(alpha: 0.35) : borderDark.withValues(alpha: 0.55),
          width: 0.85,
        ),
        boxShadow: [
          ...neomorphicEmbossDark,
          if (highlight) ...neomorphicGlowAntiqueGold(intensity: 0.12),
        ],
      );
  // Shimmer (görsel yükleme)
  static Color get shimmerBase => surfaceDarkElevated;
  static Color get shimmerHighlight => surfaceDark.withValues(alpha: 0.5);
  static Color get shimmerBaseLight => borderLight;
  static Color get shimmerHighlightLight => surfaceLight;
  static const double championCardRadius = 16;
  static const double championButtonHeight = 52;
}
