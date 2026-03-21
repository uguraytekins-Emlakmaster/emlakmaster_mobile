import 'package:flutter/material.dart';

import 'app_theme_extension.dart';
import 'design_tokens.dart';

/// Wealth Tech tema: Gold Century referansı — merkezi light/dark, semantic token'lar extension'da.
abstract final class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DesignTokens.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: DesignTokens.antiqueGold,
        secondary: DesignTokens.antiqueGold,
        surface: DesignTokens.surfaceDark,
        error: DesignTokens.danger,
        onPrimary: DesignTokens.inputTextOnGold,
        onSecondary: DesignTokens.inputTextOnGold,
        onSurface: DesignTokens.textPrimaryDark,
        onError: Colors.white,
      ),
      extensions: <ThemeExtension<dynamic>>[AppThemeExtension.dark()],
      textTheme: _textThemeDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: DesignTokens.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.inputBackgroundGold.withValues(alpha: 0.25),
        hintStyle: const TextStyle(color: DesignTokens.textTertiaryDark),
        labelStyle: const TextStyle(color: DesignTokens.textSecondaryDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: DesignTokens.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: DesignTokens.antiqueGold, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.antiqueGold,
          foregroundColor: DesignTokens.inputTextOnGold,
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
        backgroundColor: DesignTokens.surfaceDark,
        selectedItemColor: DesignTokens.antiqueGold,
        unselectedItemColor: DesignTokens.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: DesignTokens.borderDark,
      iconTheme: const IconThemeData(
        color: DesignTokens.textSecondaryDark,
        size: DesignTokens.iconMd,
      ),
    );
  }

  static TextTheme get _textThemeDark => TextTheme(
        displayLarge: DesignTokens.textDisplayTitleDark,
        headlineMedium: DesignTokens.textPageTitleDark,
        titleLarge: DesignTokens.textCardTitleDark,
        titleMedium: DesignTokens.textSectionTitleDark,
        bodyLarge: DesignTokens.textBodyDark,
        bodyMedium: DesignTokens.textBodyDark,
        bodySmall: DesignTokens.textCaptionDark,
        labelLarge: const TextStyle(
          color: DesignTokens.textPrimaryDark,
          fontSize: DesignTokens.fontSizeBase,
          fontWeight: FontWeight.w600,
        ),
      );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: DesignTokens.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: DesignTokens.antiqueGold,
        secondary: DesignTokens.antiqueGold,
        error: DesignTokens.danger,
        onPrimary: DesignTokens.inputTextOnGold,
        onSecondary: DesignTokens.inputTextOnGold,
        onSurface: DesignTokens.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.backgroundLight,
        foregroundColor: DesignTokens.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: DesignTokens.surfaceLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.surfaceLight,
        hintStyle: const TextStyle(color: DesignTokens.textTertiaryLight),
        labelStyle: const TextStyle(color: DesignTokens.textSecondaryLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: DesignTokens.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: DesignTokens.antiqueGold, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.antiqueGold,
          foregroundColor: DesignTokens.inputTextOnGold,
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
        backgroundColor: DesignTokens.surfaceLight,
        selectedItemColor: DesignTokens.antiqueGold,
        unselectedItemColor: DesignTokens.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: DesignTokens.borderLight,
      iconTheme: const IconThemeData(
        color: DesignTokens.textSecondaryLight,
        size: DesignTokens.iconMd,
      ),
      extensions: <ThemeExtension<dynamic>>[AppThemeExtension.light()],
    );
  }
}
