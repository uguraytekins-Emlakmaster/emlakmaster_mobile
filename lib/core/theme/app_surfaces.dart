import 'package:flutter/material.dart';

import 'app_theme_extension.dart';
import 'design_tokens.dart';

/// Rainbow CRM — tek kart/derinlik sistemi. Tüm yüzeyler buradan türetilir.
/// Seviye: 1 taban kart → 2 yükseltilmiş → 3 vurgu (altın çerçeve + glow).
abstract final class AppSurfaces {
  AppSurfaces._();

  static const double radiusCard = DesignTokens.radiusLg; // 16 — birincil
  static const double radiusCardLg = DesignTokens.radiusXl; // 20 — hero / geniş kartlar

  static const EdgeInsets paddingCard = EdgeInsets.all(DesignTokens.cardPaddingStandard);

  /// Seviye 1: liste / form kartı — düşük gölge, ince border.
  static BoxDecoration cardLevel1(BuildContext context, {double radius = radiusCard}) {
    final ext = AppThemeExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: ext.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: ext.border.withValues(alpha: isDark ? 0.55 : 0.45),
        width: 0.85,
      ),
      boxShadow: [
        BoxShadow(
          color: ext.shadowColor.withValues(alpha: isDark ? 0.45 : 0.12),
          blurRadius: isDark ? 8 : 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Seviye 2: önemli özet / KPI — biraz daha yüksek yüzey.
  static BoxDecoration cardLevel2(BuildContext context, {double radius = radiusCard}) {
    final ext = AppThemeExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: ext.surfaceElevated,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: ext.border.withValues(alpha: isDark ? 0.6 : 0.5),
        width: 0.9,
      ),
      boxShadow: [
        BoxShadow(
          color: ext.shadowColor.withValues(alpha: isDark ? 0.55 : 0.18),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
        ...isDark ? DesignTokens.neomorphicEmbossDark : const <BoxShadow>[],
      ],
    );
  }

  /// Seviye 3: vurgulu kart (kampanya, seçili, CTA alanı).
  static BoxDecoration cardLevel3(BuildContext context, {bool glow = true, double radius = radiusCard}) {
    final ext = AppThemeExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: ext.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: ext.brandPrimary.withValues(alpha: 0.38),
      ),
      boxShadow: [
        BoxShadow(
          color: ext.shadowColor.withValues(alpha: isDark ? 0.5 : 0.2),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
        if (glow)
          BoxShadow(
            color: ext.brandPrimary.withValues(alpha: isDark ? 0.18 : 0.14),
            blurRadius: 20,
          ),
      ],
    );
  }

  /// Cam yüzey — tek tip blur + theme uyumlu dolgu (mavi gradient yok).
  static Decoration glassCard(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radiusCard),
      border: Border.all(color: ext.brandPrimary.withValues(alpha: 0.22)),
      color: isDark
          ? ext.surface.withValues(alpha: 0.65)
          : ext.surfaceElevated.withValues(alpha: 0.92),
      boxShadow: [
        BoxShadow(
          color: ext.shadowColor.withValues(alpha: isDark ? 0.4 : 0.1),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
