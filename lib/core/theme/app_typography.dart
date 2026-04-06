import 'package:flutter/material.dart';

import 'app_theme_extension.dart';
import 'design_tokens.dart';

abstract final class AppTypography {
  AppTypography._();

  static TextStyle display(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.displayLarge!.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -0.7,
        );
  }

  static TextStyle pageHeading(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.4,
        );
  }

  static TextStyle pageEyebrow(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.titleSmall!.copyWith(
          color: ext.textSecondary,
          fontWeight: FontWeight.w600,
          height: 1.25,
        );
  }

  static TextStyle cardHeading(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w700,
          height: 1.2,
        );
  }

  static TextStyle metricValue(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.displayMedium!.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -0.5,
        );
  }

  static TextStyle metricLabel(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.labelMedium!.copyWith(
          color: ext.textSecondary,
          fontWeight: FontWeight.w600,
          height: 1.25,
        );
  }

  static TextStyle body(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: ext.textSecondary,
          height: 1.55,
        );
  }

  static TextStyle bodyStrong(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w600,
          height: 1.5,
        );
  }

  static TextStyle meta(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: ext.textTertiary,
          height: 1.4,
        );
  }

  static TextStyle sectionLabel(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          color: ext.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        );
  }

  static TextStyle primaryButton(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          color: ext.onBrand,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: 0.1,
        );
  }

  static TextStyle secondaryButton(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w700,
          height: 1.2,
        );
  }

  static EdgeInsets get cardPadding =>
      const EdgeInsets.all(DesignTokens.cardPaddingComfortable);
}
