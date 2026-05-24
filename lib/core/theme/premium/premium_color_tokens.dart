import 'package:flutter/material.dart';

/// Figma/Stitch premium palette — obsidian · midnight navy · champagne gold.
/// Ham renkler; UI bileşenleri [AppThemeExtension] / [PremiumThemeExtension] üzerinden okur.
abstract final class PremiumColorTokens {
  PremiumColorTokens._();

  // —— Obsidian base ——
  static const Color obsidian = Color(0xFF050506);
  static const Color obsidianDeep = Color(0xFF030304);
  static const Color obsidianElevated = Color(0xFF0A0A0C);

  // —— Midnight navy layers ——
  static const Color midnightNavy = Color(0xFF0B0F17);
  static const Color midnightNavySurface = Color(0xFF111827);
  static const Color midnightNavyElevated = Color(0xFF1A2233);
  static const Color midnightNavyBorder = Color(0xFF2A3344);

  // —— Champagne gold accent ——
  static const Color champagneGold = Color(0xFFC9A962);
  static const Color champagneGoldMuted = Color(0xFF9A7B45);
  static const Color champagneGoldLight = Color(0xFFE8D5A8);
  static const Color champagneGoldGlow = Color(0x33C9A962);

  // —— Text on dark ——
  static const Color textPrimary = Color(0xFFF4F4F6);
  static const Color textSecondary = Color(0xFFB8BCC8);
  static const Color textTertiary = Color(0xFF7A8194);
  static const Color textOnGold = Color(0xFF1A1408);

  // —— Semantic ——
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF453A);
  static const Color info = Color(0xFF64B5F6);

  // —— Glass overlays ——
  static const Color glassFill = Color(0xCC111827);
  static const Color glassFillLight = Color(0x991A2233);
  static const Color glassBorder = Color(0x40C9A962);
  static const Color glassHighlight = Color(0x14FFFFFF);

  // —— Light mode (executive paper) ——
  static const Color paperBackground = Color(0xFFF5F3EF);
  static const Color paperSurface = Color(0xFFFFFFFF);
  static const Color paperElevated = Color(0xFFFCFAF7);
  static const Color paperBorder = Color(0xFFE4DDD2);
  static const Color textPrimaryLight = Color(0xFF111111);
  static const Color textSecondaryLight = Color(0xFF4A4540);
}
