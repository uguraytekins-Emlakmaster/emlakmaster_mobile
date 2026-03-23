import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Rainbow CRM — tasarım sistemi özeti (kod + dokümantasyon).
///
/// **Renk:** Birincil altın [DesignTokens.antiqueGold], arka plan neredeyse siyah
/// ([DesignTokens.backgroundDark] / [DesignTokens.scaffoldDark]), yüzeyler [DesignTokens.surfaceDark].
/// Vurgu: başarı yeşili [DesignTokens.success], uyarı/hata kırmızı [DesignTokens.danger].
/// **Mavi ton kullanılmaz** (Material surfaceTint kapalı; bilgi = nötr gri).
///
/// **Tipografi:** `Theme.of(context).textTheme` — display/headline kalın, body yüksek okunurluk.
///
/// **Spacing:** 8pt grid — [DesignTokens.space2] = 8, [DesignTokens.space4] = 16, …
///
/// **Köşe:** kart/CTA [DesignTokens.radiusLg] (16) veya [DesignTokens.radiusXl] (20).
///
/// **Erişilebilirlik:** Açık/koyu mod `AppTheme.light` / `AppTheme.dark` + `ThemeMode.system`.
abstract final class RainbowCrmTheme {
  RainbowCrmTheme._();

  static const double pagePadding = DesignTokens.space4;
  static const double cardRadius = DesignTokens.radiusLg;
  static const double ctaRadius = DesignTokens.radiusXl;

  static Animation<double> gentleCurve(Animation<double> parent) =>
      CurvedAnimation(parent: parent, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
}
