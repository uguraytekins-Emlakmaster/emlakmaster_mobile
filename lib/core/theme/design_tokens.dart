/// Yerleşim, tipografi ölçeği (sayı), süre ve kırılım — **renk yok**.
/// Renkler: [ThemePalette] (düşük seviye) ve [AppThemeExtension] (UI’da tercih).
library emlakmaster_layout;

abstract final class DesignTokens {
  DesignTokens._();

  // ---------- Spacing scale (4px base)
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double cardPaddingStandard = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
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

  /// Küçük kontroller, checkbox alanları.
  static const double radiusControl = 12;

  /// Chip / filtre pill.
  static const double radiusPill = 18;

  /// Birincil kartlar (özet, KPI, içgörü).
  static const double radiusCardPrimary = 24;

  /// İkincil / liste satırı kartları.
  static const double radiusCardSecondary = 20;

  /// Alt sayfalar, formlar, modal üst köşe.
  static const double radiusSheet = 28;

  static const double uiSurfaceRadius = radiusLg;

  // ---------- Typography scale (font sizes)
  static const double fontSizeXs = 10;
  static const double fontSizeSm = 12;
  static const double fontSizeBase = 14;
  static const double fontSizeMd = 16;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 20;
  static const double fontSize2xl = 24;
  static const double fontSize3xl = 30;
  static const double fontSize4xl = 34;

  // ---------- Semantic spacing helpers
  static const double cardPaddingComfortable = 20;
  static const double cardPaddingRelaxed = 24;
  static const double sectionTitleGap = 10;
  static const double titleSubtitleGap = 6;
  static const double metricLabelGap = 4;

  // ---------- Icon scale
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  // ---------- Elevation (conceptual)
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation3 = 4;
  static const double elevation4 = 8;

  // ---------- Layout
  static const double contentPaddingHorizontal = 24;
  static const double contentPaddingVertical = 20;
  static const double screenEdgePadding = 20;

  static const double breakpointWide = 600;

  // ---------- Animation
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 280);
  static const Duration durationSlow = Duration(milliseconds: 400);

  static const double championCardRadius = 16;
  static const double championButtonHeight = 52;
}
