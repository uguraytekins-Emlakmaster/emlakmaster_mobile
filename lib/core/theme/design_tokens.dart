import 'package:flutter/material.dart';

/// Rainbow CRM / EmlakMaster design tokens.
/// Apple/Stripe/Linear seviyesinde tutarlı, zamansız token seti.
abstract final class DesignTokens {
  DesignTokens._();

  // ---------- Color (semantic)
  static const Color primary = Color(0xFF00FF41);
  static const Color primaryDark = Color(0xFF00CC34);
  static const Color secondary = Color(0xFFFFD700);
  static const Color accent = Color(0xFF00B4D8);

  static const Color success = Color(0xFF00FF41);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFE53935);
  static const Color info = Color(0xFF00B4D8);

  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color surfaceDarkElevated = Color(0xFF21262D);
  static const Color borderDark = Color(0xFF30363D);

  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFFAFAFA);
  static const Color borderLight = Color(0xFFE5E5E7);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB1BAC4);
  static const Color textTertiaryDark = Color(0xFF8B949E);

  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF6B6B70);
  static const Color textTertiaryLight = Color(0xFF8E8E93);

  // ---------- Spacing scale (4px base)
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
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

  // ---------- Typography scale (font sizes)
  static const double fontSizeXs = 10;
  static const double fontSizeSm = 12;
  static const double fontSizeBase = 14;
  static const double fontSizeMd = 16;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 20;
  static const double fontSize2xl = 24;
  static const double fontSize3xl = 30;

  // ---------- Elevation / shadow (conceptual; use Material elevation or custom)
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation3 = 4;
  static const double elevation4 = 8;

  // ---------- Animation
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 280);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // ---------- Champion / Premium (görsel ödül seviyesi)
  static const Color primaryGlow = Color(0xFF00FF41);
  static List<Color> get gradientPrimary => [primary, primaryDark];
  static List<Color> get gradientCardBorder =>
      [primary.withOpacity(0.4), accent.withOpacity(0.2)];
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
                  color: primary.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      );
  static const double championCardRadius = 16;
  static const double championButtonHeight = 52;
}
