import 'package:flutter/material.dart';

/// Dialer ekranı — [ThemeData.brightness] ile açık / koyu (iPhone Phone’a yakın).
@immutable
class DialerThemeTokens {
  const DialerThemeTokens({
    required this.pageBg,
    required this.keyFill,
    required this.keyFillPressed,
    required this.labelPrimary,
    required this.labelSecondary,
    required this.callGreen,
    required this.capsuleFill,
    required this.capsuleBorder,
    required this.keyShadow,
    required this.capsuleShadow,
    required this.inkSplash,
    required this.inkHighlight,
    required this.callButtonShadow,
    this.accentGlow = const Color(0xFFD4AF37),
  });

  final Color pageBg;
  final Color keyFill;
  final Color keyFillPressed;
  final Color labelPrimary;
  final Color labelSecondary;
  final Color callGreen;
  final Color capsuleFill;
  final Color capsuleBorder;
  final Color keyShadow;
  final Color capsuleShadow;
  final Color inkSplash;
  final Color inkHighlight;
  final Color callButtonShadow;
  final Color accentGlow;

  factory DialerThemeTokens.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const DialerThemeTokens(
        pageBg: Color(0xFF000000),
        keyFill: Color(0xFF3A3A3C),
        keyFillPressed: Color(0xFF48484A),
        labelPrimary: Color(0xFFFFFFFF),
        labelSecondary: Color(0xFF8E8E93),
        callGreen: Color(0xFF30D158),
        capsuleFill: Color(0xFF1C1C1E),
        capsuleBorder: Color(0x38FFFFFF),
        keyShadow: Color(0xB3000000),
        capsuleShadow: Color(0x99000000),
        inkSplash: Color(0x33FFFFFF),
        inkHighlight: Color(0x18FFFFFF),
        callButtonShadow: Color(0x6630D158),
      );
    }
    return const DialerThemeTokens(
      pageBg: Color(0xFFF2F2F7),
      keyFill: Color(0xFFE4E4EA),
      keyFillPressed: Color(0xFFD1D1D6),
      labelPrimary: Color(0xFF000000),
      labelSecondary: Color(0xFF8E8E93),
      callGreen: Color(0xFF34C759),
      capsuleFill: Color(0xFFFFFFFF),
      capsuleBorder: Color(0x14000000),
      keyShadow: Color(0x0D000000),
      capsuleShadow: Color(0x0A000000),
      inkSplash: Color(0x1F000000),
      inkHighlight: Color(0x0A000000),
      callButtonShadow: Color(0x22000000),
    );
  }

  /// Görüşme içi DTMF — altın vurgulu koyu tuşlar.
  factory DialerThemeTokens.inCallDtmf(BuildContext context) {
    final base = DialerThemeTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DialerThemeTokens(
      pageBg: base.pageBg,
      keyFill: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD8D8DE),
      keyFillPressed: isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC),
      labelPrimary: base.labelPrimary,
      labelSecondary: base.labelSecondary,
      callGreen: base.callGreen,
      capsuleFill: base.capsuleFill,
      capsuleBorder: base.capsuleBorder,
      keyShadow: base.keyShadow,
      capsuleShadow: base.capsuleShadow,
      inkSplash: base.inkSplash,
      inkHighlight: base.inkHighlight,
      callButtonShadow: base.callButtonShadow,
    );
  }
}
