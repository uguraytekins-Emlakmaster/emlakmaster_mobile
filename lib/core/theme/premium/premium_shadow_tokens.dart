import 'package:flutter/material.dart';

import 'premium_color_tokens.dart';

/// Premium elevation / glow shadows — kart, dock, FAB, sheet.
abstract final class PremiumShadowTokens {
  PremiumShadowTokens._();

  static List<BoxShadow> card({Color? shadowColor}) => [
        BoxShadow(
          color: (shadowColor ?? Colors.black).withValues(alpha: 0.32),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        const BoxShadow(
          color: PremiumColorTokens.champagneGoldGlow,
          blurRadius: 24,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> cardSubtle({Color? shadowColor}) => [
        BoxShadow(
          color: (shadowColor ?? Colors.black).withValues(alpha: 0.22),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> dock({Color? shadowColor}) => [
        BoxShadow(
          color: (shadowColor ?? Colors.black).withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Luxury floating dock — layered depth + ambient gold.
  static List<BoxShadow> dockLuxury({Color? shadowColor}) => [
        BoxShadow(
          color: (shadowColor ?? Colors.black).withValues(alpha: 0.55),
          blurRadius: 32,
          spreadRadius: -4,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: PremiumColorTokens.champagneGold.withValues(alpha: 0.14),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 6),
        ),
      ];

  /// Executive cockpit card — depth + edge glow.
  static List<BoxShadow> executiveCard({Color? shadowColor}) => [
        BoxShadow(
          color: (shadowColor ?? Colors.black).withValues(alpha: 0.38),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 8),
        ),
        const BoxShadow(
          color: PremiumColorTokens.champagneGoldGlow,
          blurRadius: 28,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> ambientGlow({Color? color}) => [
        BoxShadow(
          color: (color ?? PremiumColorTokens.champagneGold)
              .withValues(alpha: 0.12),
          blurRadius: 36,
          spreadRadius: -8,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> goldGlow() => [
        BoxShadow(
          color: PremiumColorTokens.champagneGold.withValues(alpha: 0.18),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  /// Selected tab in floating dock — tight luxury halo.
  static List<BoxShadow> navSelectedGlow() => [
        BoxShadow(
          color: PremiumColorTokens.champagneGold.withValues(alpha: 0.32),
          blurRadius: 16,
          spreadRadius: -2,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: PremiumColorTokens.champagneGold.withValues(alpha: 0.12),
          blurRadius: 28,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> kpiCellGlow(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.2),
          blurRadius: 14,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> sheet({Color? shadowColor}) => [
        BoxShadow(
          color: (shadowColor ?? Colors.black).withValues(alpha: 0.5),
          blurRadius: 32,
          offset: const Offset(0, -4),
        ),
      ];
}
