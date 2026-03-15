import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Premium tema: koyu + açık; design tokens kullanır.
abstract final class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DesignTokens.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: DesignTokens.primary,
        secondary: DesignTokens.secondary,
        surface: DesignTokens.surfaceDark,
        error: DesignTokens.danger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: DesignTokens.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: DesignTokens.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: DesignTokens.primary,
        secondary: DesignTokens.secondary,
        error: DesignTokens.danger,
        onPrimary: Colors.black,
        onSurface: DesignTokens.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.backgroundLight,
        foregroundColor: DesignTokens.textPrimaryLight,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: DesignTokens.surfaceLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
      ),
    );
  }
}
