import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

/// Çağrı sonuç etiketleri — liste, KPI ve hızlı yakalama için ortak renkler.
class CallOutcomeStyle {
  const CallOutcomeStyle({
    required this.fill,
    required this.border,
    required this.text,
  });

  final Color fill;
  final Color border;
  final Color text;

  static CallOutcomeStyle resolve(AppThemeExtension ext, String label) {
    final l = label.toLowerCase();
    if (l.contains('ulaşılamadı') ||
        l.contains('cevapsız') ||
        l.contains('missed') ||
        l.contains('meşgul') ||
        l.contains('cevap yok') ||
        l.contains('başarısız')) {
      return CallOutcomeStyle(
        fill: ext.danger.withValues(alpha: 0.14),
        border: ext.danger.withValues(alpha: 0.35),
        text: ext.danger,
      );
    }
    if (l.contains('randevu') ||
        l.contains('ulaşıldı') ||
        l.contains('emlak master') ||
        l.contains('cevaplandı') ||
        l.contains('bağlandı') ||
        l.contains('tamamlandı')) {
      return CallOutcomeStyle(
        fill: ext.success.withValues(alpha: 0.14),
        border: ext.success.withValues(alpha: 0.32),
        text: ext.success,
      );
    }
    if (l.contains('görüşme') ||
        l.contains('tekrar') ||
        l.contains('bekleniyor') ||
        l.contains('operasyon') ||
        l.contains('geri aranacak')) {
      return CallOutcomeStyle(
        fill: ext.warning.withValues(alpha: 0.14),
        border: ext.warning.withValues(alpha: 0.32),
        text: ext.warning,
      );
    }
    return CallOutcomeStyle(
      fill: ext.accent.withValues(alpha: 0.11),
      border: ext.accent.withValues(alpha: 0.28),
      text: ext.accent,
    );
  }

  /// Üst durum pill’i ile alt sonuç pill’i aynı anlama geliyorsa üstte gösterme.
  static bool shouldHideStatusPill({
    required String? statusLabel,
    required String outcomeLabel,
  }) {
    final s = statusLabel?.trim().toLowerCase() ?? '';
    final o = outcomeLabel.trim().toLowerCase();
    if (s.isEmpty) return true;
    if (s == o) return true;
    if (s.contains('sonuç bekleniyor') && o.contains('bekleniyor')) {
      return true;
    }
    if (s.contains('kayıt tamamlandı') &&
        (o.contains('ulaşıldı') || o.contains('tamamlandı'))) {
      return true;
    }
    return false;
  }
}
