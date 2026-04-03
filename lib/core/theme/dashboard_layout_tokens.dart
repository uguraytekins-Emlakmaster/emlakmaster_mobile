import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Danışman / özet dashboard’ları için Apple-tarzı 3 katman (Hero → Operational → Insight)
/// ve tutarlı kart ölçekleri. Renkler [AppThemeExtension] üzerinden verilir.
abstract final class DashboardLayoutTokens {
  DashboardLayoutTokens._();

  // —— Page rhythm ——
  static const double horizontalPadding = DesignTokens.space6;
  static const double pageTopInset = DesignTokens.space2;
  static const double pageBottomInset = DesignTokens.space3;

  /// Hero (selam) → Operasyonel (KPI, CTA, takip) arası
  static const double gapHeroToOperational = 6;

  /// Operasyonel blok içi (KPI ↔ CTA ↔ kartlar)
  static const double gapOperationalTight = 6;
  static const double gapOperational = 8;

  /// Insight katmanı bölümleri (pipeline, keşif, ticker, …)
  static const double gapInsightSection = 10;

  // —— Card scale (S / M / L / XL) ——
  static const double radiusCardS = DesignTokens.radiusMd;
  static const double radiusCardM = DesignTokens.radiusLg;
  static const double radiusCardL = DesignTokens.radiusXl;
  static const double radiusCardXL = DesignTokens.radius2xl;

  static const double minHeightKpi = 56;
  static const double minHeightOperationalCard = 72;
  static const double minHeightInsightCard = 88;
  static const double minHeightHeroCard = 120;

  /// Scroll içeriğinin son satırı ile alt krom (nav / dock) arasında nefes payı.
  /// Yüzen FAB kaldırıldı; alan çoğunlukla [Scaffold] gövdesinde rezerve.
  static double bottomScrollPadding(BuildContext context, {required bool showFab}) {
    return contentScrollBottomInset(context);
  }

  /// Ana kabuk / özet sayfaları — alt gezinme veya docked CTA ile uyumlu alt boşluk.
  static double shellScrollBottomPadding(BuildContext context) {
    return contentScrollBottomInset(context);
  }

  static double contentScrollBottomInset(BuildContext context) {
    return DesignTokens.space6;
  }
}
