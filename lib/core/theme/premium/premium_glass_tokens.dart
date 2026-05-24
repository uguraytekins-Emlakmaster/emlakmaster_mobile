import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_tokens.dart';
import 'premium_color_tokens.dart';
import 'premium_shadow_tokens.dart';

/// Glassmorphism decorations — nav dock, sheets, cards, app bars.
abstract final class PremiumGlassTokens {
  PremiumGlassTokens._();

  static const double defaultBlur = 18;
  static const double heavyBlur = 28;

  static BoxDecoration surface({
    required bool isDark,
    double radius = DesignTokens.radiusCardPrimary,
    bool goldBorder = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: isDark
          ? PremiumColorTokens.glassFill
          : PremiumColorTokens.paperSurface.withValues(alpha: 0.92),
      border: Border.all(
        color: goldBorder
            ? PremiumColorTokens.glassBorder
            : (isDark
                ? PremiumColorTokens.midnightNavyBorder.withValues(alpha: 0.65)
                : PremiumColorTokens.paperBorder),
        width: goldBorder ? 1 : 0.75,
      ),
      boxShadow: PremiumShadowTokens.cardSubtle(),
    );
  }

  static Widget blur({
    required Widget child,
    double sigma = defaultBlur,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }

  static LinearGradient heroGradient({required bool isDark}) {
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          PremiumColorTokens.midnightNavy,
          PremiumColorTokens.obsidian,
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        PremiumColorTokens.paperElevated,
        PremiumColorTokens.paperBackground,
      ],
    );
  }

  static LinearGradient goldAccentGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        PremiumColorTokens.champagneGoldLight,
        PremiumColorTokens.champagneGold,
      ],
    );
  }
}
