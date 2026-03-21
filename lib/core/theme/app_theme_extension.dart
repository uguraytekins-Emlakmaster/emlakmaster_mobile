import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Semantic theme tokens — tek kaynak; light/dark otomatik.
/// Bileşenler doğrudan renk yerine bu token'ları kullanmalı.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.card,
    required this.foreground,
    required this.foregroundSecondary,
    required this.foregroundMuted,
    required this.border,
    required this.borderSubdle,
    required this.inputBackground,
    required this.inputForeground,
    required this.inputBorder,
    required this.popoverBackground,
    required this.popoverForeground,
    required this.chartBackground,
    required this.shadowColor,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color card;
  final Color foreground;
  final Color foregroundSecondary;
  final Color foregroundMuted;
  final Color border;
  final Color borderSubdle;
  final Color inputBackground;
  final Color inputForeground;
  final Color inputBorder;
  final Color popoverBackground;
  final Color popoverForeground;
  final Color chartBackground;
  final Color shadowColor;
  final Color shimmerBase;
  final Color shimmerHighlight;

  static AppThemeExtension light() {
    return const AppThemeExtension(
      background: Color(0xFFF5F5F7),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFFAFAFA),
      card: Color(0xFFFFFFFF),
      foreground: Color(0xFF1C1C1E),
      foregroundSecondary: Color(0xFF6B6B70),
      foregroundMuted: Color(0xFF8E8E93),
      border: Color(0xFFE5E5E7),
      borderSubdle: Color(0xFFE5E5E7),
      inputBackground: Color(0xFFFFFFFF),
      inputForeground: Color(0xFF1C1C1E),
      inputBorder: Color(0xFFE5E5E7),
      popoverBackground: Color(0xFFFFFFFF),
      popoverForeground: Color(0xFF1C1C1E),
      chartBackground: Color(0xFFFAFAFA),
      shadowColor: Color(0x14000000),
      shimmerBase: Color(0xFFE5E5E7),
      shimmerHighlight: Color(0xFFFFFFFF),
    );
  }

  static AppThemeExtension dark() {
    return AppThemeExtension(
      background: DesignTokens.backgroundDark,
      surface: DesignTokens.surfaceDark,
      surfaceElevated: DesignTokens.surfaceDarkElevated,
      card: DesignTokens.surfaceDark,
      foreground: DesignTokens.textPrimaryDark,
      foregroundSecondary: DesignTokens.textSecondaryDark,
      foregroundMuted: DesignTokens.textTertiaryDark,
      border: DesignTokens.borderDark,
      borderSubdle: DesignTokens.borderDark.withValues(alpha: 0.6),
      inputBackground: DesignTokens.inputBackgroundGold.withValues(alpha: 0.25),
      inputForeground: DesignTokens.textPrimaryDark,
      inputBorder: DesignTokens.borderDark,
      popoverBackground: DesignTokens.surfaceDark,
      popoverForeground: DesignTokens.textPrimaryDark,
      chartBackground: DesignTokens.surfaceDarkElevated,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shimmerBase: DesignTokens.surfaceDarkElevated,
      shimmerHighlight: DesignTokens.surfaceDark.withValues(alpha: 0.5),
    );
  }

  /// BuildContext'ten güvenli erişim; extension yoksa dark döner.
  static AppThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>() ?? AppThemeExtension.dark();
  }

  @override
  AppThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? card,
    Color? foreground,
    Color? foregroundSecondary,
    Color? foregroundMuted,
    Color? border,
    Color? borderSubdle,
    Color? inputBackground,
    Color? inputForeground,
    Color? inputBorder,
    Color? popoverBackground,
    Color? popoverForeground,
    Color? chartBackground,
    Color? shadowColor,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      card: card ?? this.card,
      foreground: foreground ?? this.foreground,
      foregroundSecondary: foregroundSecondary ?? this.foregroundSecondary,
      foregroundMuted: foregroundMuted ?? this.foregroundMuted,
      border: border ?? this.border,
      borderSubdle: borderSubdle ?? this.borderSubdle,
      inputBackground: inputBackground ?? this.inputBackground,
      inputForeground: inputForeground ?? this.inputForeground,
      inputBorder: inputBorder ?? this.inputBorder,
      popoverBackground: popoverBackground ?? this.popoverBackground,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      chartBackground: chartBackground ?? this.chartBackground,
      shadowColor: shadowColor ?? this.shadowColor,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      card: Color.lerp(card, other.card, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      foregroundSecondary: Color.lerp(foregroundSecondary, other.foregroundSecondary, t)!,
      foregroundMuted: Color.lerp(foregroundMuted, other.foregroundMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubdle: Color.lerp(borderSubdle, other.borderSubdle, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputForeground: Color.lerp(inputForeground, other.inputForeground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      popoverBackground: Color.lerp(popoverBackground, other.popoverBackground, t)!,
      popoverForeground: Color.lerp(popoverForeground, other.popoverForeground, t)!,
      chartBackground: Color.lerp(chartBackground, other.chartBackground, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}
