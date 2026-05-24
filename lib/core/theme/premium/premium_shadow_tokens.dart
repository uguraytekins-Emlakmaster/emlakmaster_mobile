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
        BoxShadow(
          color: PremiumColorTokens.champagneGoldGlow,
          blurRadius: 24,
          offset: const Offset(0, 2),
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

  static List<BoxShadow> goldGlow() => [
        BoxShadow(
          color: PremiumColorTokens.champagneGold.withValues(alpha: 0.18),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 4),
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
