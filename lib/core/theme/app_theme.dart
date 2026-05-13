import 'package:flutter/material.dart';

import 'app_theme_extension.dart';
import 'design_tokens.dart';
import 'theme_palette.dart';

/// Wealth Tech tema: Gold Century — merkezi light/dark; semantic token'lar [AppThemeExtension]'da.
abstract final class AppTheme {
  static final ThemeData _darkTheme = _buildTheme(isDark: true);
  static final ThemeData _lightTheme = _buildTheme(isDark: false);

  static ThemeData dark() => _darkTheme;
  static ThemeData light() => _lightTheme;

  static ThemeData _buildTheme({required bool isDark}) {
    final ext = isDark ? AppThemeExtension.dark() : AppThemeExtension.light();
    final textTheme = isDark ? _textThemeDark : _textThemeLight;
    final divider = isDark ? ThemePalette.borderDark : ThemePalette.borderLight;
    final appBarBackground =
        isDark ? ThemePalette.scaffoldDark : ThemePalette.backgroundLight;
    final scheme = isDark
        ? const ColorScheme.dark(
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
          )
        : const ColorScheme.light(
            primary: ThemePalette.antiqueGold,
            secondary: ThemePalette.antiqueGold,
            surface: ThemePalette.surfaceLight,
            onSurface: ThemePalette.textPrimaryLight,
            onPrimary: ThemePalette.inputTextOnGold,
            onSecondary: ThemePalette.inputTextOnGold,
            onSurfaceVariant: ThemePalette.textSecondaryLight,
            error: ThemePalette.danger,
            onError: Colors.white,
            outline: ThemePalette.borderLight,
            surfaceContainerHighest: ThemePalette.surfaceLightElevated,
            surfaceTint: Colors.transparent,
            primaryContainer: Color(0xFFF5EFE6),
            onPrimaryContainer: Color(0xFF3D3428),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: ext.background,
      canvasColor: ext.background,
      cardColor: ext.card,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[ext],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: ext.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ext.textPrimary,
          fontSize: DesignTokens.fontSizeXl,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(
          color: ThemePalette.antiqueGold,
          size: 22,
        ),
        actionsIconTheme: const IconThemeData(
          color: ThemePalette.antiqueGold,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: ext.card,
        elevation: isDark ? 0 : 1,
        shadowColor: ext.shadowColor.withValues(alpha: isDark ? 0.48 : 0.14),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
          side:
              BorderSide(color: divider.withValues(alpha: isDark ? 0.5 : 0.9)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ext.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: ext.textSecondary,
          height: 1.52,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ext.surface,
        modalBackgroundColor: ext.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusSheet),
          ),
        ),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: ext.infoSurface,
        surfaceTintColor: Colors.transparent,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        padding: const EdgeInsetsDirectional.only(
          start: DesignTokens.space4,
          end: DesignTokens.space2,
          top: DesignTokens.space3,
          bottom: DesignTokens.space3,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: ext.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(color: ext.border.withValues(alpha: 0.55)),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: ext.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? ext.surfaceElevated : const Color(0xFF242428),
        contentTextStyle: TextStyle(
          color: isDark ? ext.textPrimary : ThemePalette.brandWhite,
          fontSize: DesignTokens.fontSizeSm,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: ThemePalette.antiqueGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.inputBackground,
        hintStyle: TextStyle(color: ext.textPassive),
        labelStyle: TextStyle(color: ext.textSecondary),
        prefixIconColor: ext.textSecondary,
        suffixIconColor: ext.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide(color: ext.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(
            color: ThemePalette.antiqueGold,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide(color: ext.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide(color: ext.danger, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ext.accent,
          foregroundColor: ext.onBrand,
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ext.accent,
          foregroundColor: ext.onBrand,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ext.textPrimary,
          side: BorderSide(color: ext.border.withValues(alpha: 0.85)),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ext.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ext.accent,
        foregroundColor: ext.onBrand,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: ext.textSecondary,
        textColor: ext.textPrimary,
        tileColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: ext.surface,
        indicatorColor: ext.accent.withValues(alpha: isDark ? 0.18 : 0.14),
        selectedIconTheme: IconThemeData(color: ext.accent),
        unselectedIconTheme: IconThemeData(
          color: isDark ? ext.textTertiary : ext.textPassive,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: isDark ? ext.textSecondary : ext.textPassive,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ext.surface,
        indicatorColor: ext.accent.withValues(alpha: isDark ? 0.18 : 0.14),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ext.surface,
        selectedItemColor: ext.accent,
        unselectedItemColor: isDark ? ext.textTertiary : ext.textPassive,
        selectedIconTheme: IconThemeData(color: ext.accent),
        unselectedIconTheme: IconThemeData(
          color: isDark ? ext.textTertiary : ext.textPassive,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: ext.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: ext.surfaceElevated,
        headerForegroundColor: ext.textPrimary,
      ),
      dividerColor: divider,
      dividerTheme: DividerThemeData(
        color: divider.withValues(alpha: isDark ? 0.7 : 1),
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: ext.textSecondary,
        size: DesignTokens.iconMd,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ext.surfaceElevated,
        disabledColor: ext.border.withValues(alpha: 0.4),
        selectedColor: ext.accent.withValues(alpha: isDark ? 0.24 : 0.2),
        checkmarkColor: ext.onBrand,
        deleteIconColor: ext.textSecondary,
        side: BorderSide(color: ext.border.withValues(alpha: isDark ? 0.55 : 0.72)),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space1,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: ext.accent.withValues(alpha: 0.92),
        textColor: ext.onBrand,
        smallSize: 18,
        largeSize: 22,
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
          fontWeight: FontWeight.w600,
          height: 1.12,
          letterSpacing: -0.25,
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
          fontWeight: FontWeight.w800,
          height: 1.22,
          letterSpacing: 0.15,
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
          fontWeight: FontWeight.w400,
          height: 1.58,
        ),
        bodyMedium: TextStyle(
          color: ThemePalette.textSecondaryDark,
          fontSize: DesignTokens.fontSizeBase,
          fontWeight: FontWeight.w400,
          height: 1.58,
        ),
        bodySmall: TextStyle(
          color: ThemePalette.textTertiaryDark,
          fontSize: DesignTokens.fontSizeSm,
          height: 1.45,
          fontWeight: FontWeight.w500,
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
          height: 1.4,
          letterSpacing: 0.35,
        ),
      );

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
          fontWeight: FontWeight.w600,
          height: 1.12,
          letterSpacing: -0.25,
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
          fontWeight: FontWeight.w800,
          height: 1.22,
          letterSpacing: 0.15,
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
          fontWeight: FontWeight.w400,
          height: 1.58,
        ),
        bodyMedium: TextStyle(
          color: ThemePalette.textSecondaryLight,
          fontSize: DesignTokens.fontSizeBase,
          fontWeight: FontWeight.w400,
          height: 1.58,
        ),
        bodySmall: TextStyle(
          color: ThemePalette.textTertiaryLight,
          fontSize: DesignTokens.fontSizeSm,
          height: 1.45,
          fontWeight: FontWeight.w500,
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
          height: 1.4,
          letterSpacing: 0.35,
        ),
      );
}
