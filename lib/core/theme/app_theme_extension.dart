import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'theme_palette.dart';

/// Semantic theme tokens — tek kaynak; light/dark otomatik.
/// Bileşenler renk için [textPrimary], [accent], [surface] vb. kullanmalı; ham renk için [ThemePalette] değil.
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
    required this.brandPrimary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.onBrand,
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

  final Color brandPrimary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color onBrand;

  Color get textPrimary => foreground;
  Color get textSecondary => foregroundSecondary;
  Color get textTertiary => foregroundMuted;
  Color get accent => brandPrimary;
  Color get borderSubtle => borderSubdle;

  /// Üst/alt gradient (FAB, hero) — [background] → [surface].
  List<Color> get gradientPrimary => <Color>[background, surface];

  /// Altın vurgu kenar gradient’i (özel kart çerçeveleri).
  List<Color> get gradientAccentBorder => <Color>[
        brandPrimary.withValues(alpha: 0.35),
        brandPrimary.withValues(alpha: 0.1),
      ];

  /// Filigran / watermark için düşük opaklık marka rengi.
  Color get brandWatermark => brandPrimary.withValues(alpha: 0.031);

  /// Durum / bilgi ikonları (ThemePalette.info ile uyumlu).
  Color get info => ThemePalette.info;

  /// Koyu yüzey üzerinde ikincil panel (navy).
  Color get brandNavy => ThemePalette.brandNavy;

  Color get brandNavyLight => ThemePalette.brandNavyLight;

  /// Açık metin / FAB ön planı (açık ton).
  Color get onAccentLight => ThemePalette.brandWhite;

  /// Dashboard / insight kartları — neomorphic hafif gölge.
  BoxDecoration surfaceCardDecoration({bool highlight = false, Color? surfaceColor}) {
    return BoxDecoration(
      color: surfaceColor ?? surface,
      borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
      border: Border.all(
        color: highlight ? brandPrimary.withValues(alpha: 0.35) : border.withValues(alpha: 0.55),
        width: 0.85,
      ),
      boxShadow: [
        BoxShadow(
          color: foreground.withValues(alpha: 0.03),
          offset: const Offset(-1.5, -1.5),
          blurRadius: 3,
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.45),
          offset: const Offset(1.5, 1.5),
          blurRadius: 4,
        ),
        if (highlight)
          BoxShadow(
            color: brandPrimary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
      ],
    );
  }

  /// Pipeline / şampiyon kartları.
  BoxDecoration championCardDecoration({bool withGlow = false, Color? borderColor}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
      border: Border.all(color: borderColor ?? border),
      boxShadow: withGlow
          ? [
              BoxShadow(
                color: brandPrimary.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  static AppThemeExtension light() {
    return const AppThemeExtension(
      background: ThemePalette.backgroundLight,
      surface: ThemePalette.surfaceLight,
      surfaceElevated: ThemePalette.surfaceLightElevated,
      card: ThemePalette.surfaceLight,
      foreground: ThemePalette.textPrimaryLight,
      foregroundSecondary: ThemePalette.textSecondaryLight,
      foregroundMuted: ThemePalette.textTertiaryLight,
      border: ThemePalette.borderLight,
      borderSubdle: ThemePalette.borderLight,
      inputBackground: ThemePalette.surfaceLight,
      inputForeground: ThemePalette.textPrimaryLight,
      inputBorder: ThemePalette.borderLight,
      popoverBackground: ThemePalette.surfaceLight,
      popoverForeground: ThemePalette.textPrimaryLight,
      chartBackground: ThemePalette.surfaceLightElevated,
      shadowColor: Color(0x14000000),
      shimmerBase: ThemePalette.shimmerBaseLight,
      shimmerHighlight: ThemePalette.shimmerHighlightLight,
      brandPrimary: ThemePalette.antiqueGold,
      success: ThemePalette.success,
      warning: ThemePalette.warning,
      danger: ThemePalette.danger,
      onBrand: ThemePalette.inputTextOnGold,
    );
  }

  static AppThemeExtension dark() {
    return AppThemeExtension(
      background: ThemePalette.scaffoldDark,
      surface: ThemePalette.surfaceDark,
      surfaceElevated: ThemePalette.surfaceDarkElevated,
      card: ThemePalette.surfaceDark,
      foreground: ThemePalette.textPrimaryDark,
      foregroundSecondary: ThemePalette.textSecondaryDark,
      foregroundMuted: ThemePalette.textTertiaryDark,
      border: ThemePalette.borderDark,
      borderSubdle: ThemePalette.borderDark.withValues(alpha: 0.6),
      inputBackground: ThemePalette.inputBackgroundGold.withValues(alpha: 0.25),
      inputForeground: ThemePalette.textPrimaryDark,
      inputBorder: ThemePalette.borderDark,
      popoverBackground: ThemePalette.surfaceDark,
      popoverForeground: ThemePalette.textPrimaryDark,
      chartBackground: ThemePalette.surfaceDarkElevated,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shimmerBase: ThemePalette.shimmerBaseDark,
      shimmerHighlight: ThemePalette.shimmerHighlightDark,
      brandPrimary: ThemePalette.antiqueGold,
      success: ThemePalette.success,
      warning: ThemePalette.warning,
      danger: ThemePalette.danger,
      onBrand: ThemePalette.inputTextOnGold,
    );
  }

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
    Color? brandPrimary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? onBrand,
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
      brandPrimary: brandPrimary ?? this.brandPrimary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      onBrand: onBrand ?? this.onBrand,
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
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
    );
  }
}
