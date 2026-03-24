import 'package:emlakmaster_mobile/widgets/magic_call_wizard_fab.dart';
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

  /// Alt gezinme + yüzen Magic Call FAB ile içerik çakışmasın; ekstra güvenli alan.
  static double bottomScrollPadding(BuildContext context, {required bool showFab}) {
    return MagicCallWizardFab.scrollBottomPadding(context, showFab: showFab);
  }

  /// Yönetici / broker shell: FAB yok; alt [NavigationBar] + güvenli alan.
  static double shellScrollBottomPadding(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return safe + kBottomNavigationBarHeight + DesignTokens.space4;
  }
}
