import 'package:flutter/material.dart';

import 'app_theme_extension.dart';
import 'design_tokens.dart';
import 'theme_palette.dart';

/// Wealth Tech tema: Gold Century — merkezi light/dark; semantic token'lar [AppThemeExtension]'da.
abstract final class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ThemePalette.scaffoldDark,
      colorScheme: const ColorScheme.dark(
        primary: ThemePalette.antiqueGold,
        secondary: ThemePalette.antiqueGold,
        surface: ThemePalette.surfaceDark,
        onSurface: ThemePalette.textPrimaryDark,
        onPrimary: ThemePalette.inputTextOnGold,
        onSecondary: ThemePalette.inputTextOnGold,
        onSurfaceVariant: ThemePalette.textSecondaryDark,
        error: ThemePalette.danger,
        onError: Colors.white,
        outline: ThemePalette.borderDark,
        surfaceContainerHighest: ThemePalette.surfaceDarkElevated,
        surfaceTint: Colors.transparent,
        primaryContainer: Color(0xFF2A2418),
        onPrimaryContainer: ThemePalette.antiqueGold,
      ),
      extensions: <ThemeExtension<dynamic>>[AppThemeExtension.dark()],
      textTheme: _textThemeDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: ThemePalette.scaffoldDark,
        foregroundColor: ThemePalette.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: ThemePalette.textPrimaryDark,
          fontSize: DesignTokens.fontSizeXl,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(
          color: ThemePalette.antiqueGold,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: ThemePalette.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemePalette.inputBackgroundGold.withValues(alpha: 0.25),
        hintStyle: const TextStyle(color: ThemePalette.textTertiaryDark),
        labelStyle: const TextStyle(color: ThemePalette.textSecondaryDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: ThemePalette.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide:
              const BorderSide(color: ThemePalette.antiqueGold, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemePalette.antiqueGold,
          foregroundColor: ThemePalette.inputTextOnGold,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space6,
            vertical: DesignTokens.space3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ThemePalette.surfaceDark,
        selectedItemColor: ThemePalette.antiqueGold,
        unselectedItemColor: ThemePalette.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: ThemePalette.borderDark,
      iconTheme: const IconThemeData(
        color: ThemePalette.textSecondaryDark,
        size: DesignTokens.iconMd,
      ),
    );
  }

  static TextTheme get _textThemeDark => const TextTheme(
        displayLarge: TextStyle(
          color: ThemePalette.textPrimaryDark,
          fontSize: DesignTokens.fontSize4xl,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -0.7,
        ),
        displayMedium: TextStyle(
          color: ThemePalette.textPrimaryDark,
          fontSize: DesignTokens.fontSize3xl,
          fontWeight: FontWeight.w800,
          height: 1.0,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: ThemePalette.antiqueGold,
          fontSize: DesignTokens.fontSize2xl,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          color: ThemePalette.textPrimaryDark,
          fontSize: DesignTokens.fontSize2xl,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: ThemePalette.textPrimaryDark,
          fontSize: DesignTokens.fontSizeLg,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleMedium: TextStyle(
          color: ThemePalette.textPrimaryDark,
          fontSize: DesignTokens.fontSizeMd,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 0.2,
        ),
        titleSmall: TextStyle(
          color: ThemePalette.textSecondaryDark,
          fontSize: DesignTokens.fontSizeBase,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          color: ThemePalette.textSecondaryDark,
          fontSize: DesignTokens.fontSizeMd,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          color: ThemePalette.textSecondaryDark,
          fontSize: DesignTokens.fontSizeBase,
          height: 1.55,
        ),
        bodySmall: TextStyle(
          color: ThemePalette.textTertiaryDark,
          fontSize: DesignTokens.fontSizeSm,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: ThemePalette.textPrimaryDark,
          fontSize: DesignTokens.fontSizeBase,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        labelMedium: TextStyle(
          color: ThemePalette.textSecondaryDark,
          fontSize: DesignTokens.fontSizeSm,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        labelSmall: TextStyle(
          color: ThemePalette.textTertiaryDark,
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ThemePalette.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: ThemePalette.antiqueGold,
        secondary: ThemePalette.antiqueGold,
        onSurface: ThemePalette.textPrimaryLight,
        onPrimary: ThemePalette.inputTextOnGold,
        onSecondary: ThemePalette.inputTextOnGold,
        onSurfaceVariant: ThemePalette.textSecondaryLight,
        error: ThemePalette.danger,
        outline: ThemePalette.borderLight,
        surfaceContainerHighest: ThemePalette.surfaceLightElevated,
        surfaceTint: Colors.transparent,
        primaryContainer: Color(0xFFF5EFE6),
        onPrimaryContainer: Color(0xFF3D3428),
      ),
      textTheme: _textThemeLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: ThemePalette.backgroundLight,
        foregroundColor: ThemePalette.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: ThemePalette.textPrimaryLight,
          fontSize: DesignTokens.fontSizeXl,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(
          color: ThemePalette.antiqueGold,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: ThemePalette.surfaceLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemePalette.surfaceLight,
        hintStyle: const TextStyle(color: ThemePalette.textTertiaryLight),
        labelStyle: const TextStyle(color: ThemePalette.textSecondaryLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: ThemePalette.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide:
              const BorderSide(color: ThemePalette.antiqueGold, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemePalette.antiqueGold,
          foregroundColor: ThemePalette.inputTextOnGold,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space6,
            vertical: DesignTokens.space3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ThemePalette.surfaceLight,
        selectedItemColor: ThemePalette.antiqueGold,
        unselectedItemColor: ThemePalette.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: ThemePalette.borderLight,
      iconTheme: const IconThemeData(
        color: ThemePalette.textSecondaryLight,
        size: DesignTokens.iconMd,
      ),
      extensions: <ThemeExtension<dynamic>>[AppThemeExtension.light()],
    );
  }

  static TextTheme get _textThemeLight => const TextTheme(
        displayLarge: TextStyle(
          color: ThemePalette.textPrimaryLight,
          fontSize: DesignTokens.fontSize4xl,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -0.7,
        ),
        displayMedium: TextStyle(
          color: ThemePalette.textPrimaryLight,
          fontSize: DesignTokens.fontSize3xl,
          fontWeight: FontWeight.w800,
          height: 1.0,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: ThemePalette.antiqueGold,
          fontSize: DesignTokens.fontSize2xl,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          color: ThemePalette.textPrimaryLight,
          fontSize: DesignTokens.fontSize2xl,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: ThemePalette.textPrimaryLight,
          fontSize: DesignTokens.fontSizeLg,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleMedium: TextStyle(
          color: ThemePalette.textPrimaryLight,
          fontSize: DesignTokens.fontSizeMd,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 0.2,
        ),
        titleSmall: TextStyle(
          color: ThemePalette.textSecondaryLight,
          fontSize: DesignTokens.fontSizeBase,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          color: ThemePalette.textSecondaryLight,
          fontSize: DesignTokens.fontSizeMd,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          color: ThemePalette.textSecondaryLight,
          fontSize: DesignTokens.fontSizeBase,
          height: 1.55,
        ),
        bodySmall: TextStyle(
          color: ThemePalette.textTertiaryLight,
          fontSize: DesignTokens.fontSizeSm,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: ThemePalette.textPrimaryLight,
          fontSize: DesignTokens.fontSizeBase,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        labelMedium: TextStyle(
          color: ThemePalette.textSecondaryLight,
          fontSize: DesignTokens.fontSizeSm,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        labelSmall: TextStyle(
          color: ThemePalette.textTertiaryLight,
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      );
}
