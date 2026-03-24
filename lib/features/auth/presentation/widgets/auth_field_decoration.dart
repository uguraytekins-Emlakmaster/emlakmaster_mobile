import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
/// Giriş / kayıt ekranlarında tutarlı input görünümü.
abstract final class AuthFieldDecoration {
  static InputDecoration build(
    BuildContext context, {
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    final ext = AppThemeExtension.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: BorderSide(color: ext.border),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.7)),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: ext.textTertiary),
      hintStyle: TextStyle(color: ext.textTertiary),
      prefixIcon: prefix,
      suffixIcon: suffix,
      prefixIconColor: ext.textTertiary,
      suffixIconColor: ext.textTertiary,
      filled: true,
      fillColor: ext.surface,
      enabledBorder: border,
      focusedBorder: focusBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: ext.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: ext.danger),
      ),
    );
  }
}
