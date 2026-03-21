import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Giriş / kayıt ekranlarında tutarlı input görünümü.
abstract final class AuthFieldDecoration {
  static InputDecoration build({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: const BorderSide(color: DesignTokens.borderDark),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: BorderSide(color: DesignTokens.antiqueGold.withValues(alpha: 0.7)),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: DesignTokens.textTertiaryDark),
      hintStyle: const TextStyle(color: DesignTokens.textTertiaryDark),
      prefixIcon: prefix,
      suffixIcon: suffix,
      prefixIconColor: DesignTokens.textTertiaryDark,
      suffixIconColor: DesignTokens.textTertiaryDark,
      filled: true,
      fillColor: DesignTokens.surfaceDark,
      enabledBorder: border,
      focusedBorder: focusBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: DesignTokens.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: DesignTokens.danger),
      ),
    );
  }
}
