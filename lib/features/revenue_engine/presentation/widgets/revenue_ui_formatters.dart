import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';

/// CRM satır / detay için kısa Türkçe etiketler.
String revenueBandLabelTr(RevenueLeadBand band) {
  switch (band) {
    case RevenueLeadBand.hot:
      return 'Sıcak';
    case RevenueLeadBand.warm:
      return 'Ilık';
    case RevenueLeadBand.cold:
      return 'Soğuk';
  }
}

String revenueNextActionVerbTr(RevenueNextActionKind kind) {
  switch (kind) {
    case RevenueNextActionKind.call:
      return 'Ara';
    case RevenueNextActionKind.message:
      return 'Mesaj';
    case RevenueNextActionKind.wait:
      return 'Bekle';
  }
}

String revenueRelativeTimeHint(DateTime t) {
  final now = DateTime.now();
  final d = DateTime(t.year, t.month, t.day);
  final nd = DateTime(now.year, now.month, now.day);
  if (d == nd) return 'bugün';
  if (d == nd.add(const Duration(days: 1))) return 'yarın';
  if (d == nd.subtract(const Duration(days: 1))) return 'dün';
  return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
}

/// Tek satır aksiyon ipucu (liste satırı).
String revenueNextActionLine(CustomerRevenueSignals s) {
  if (s.recommendationSuppressed) {
    return s.suppressionReason ?? 'Öneri gizlendi';
  }
  final v = revenueNextActionVerbTr(s.nextAction);
  final when = revenueRelativeTimeHint(s.nextActionTime);
  return '$v · $when';
}

/// “Neden değerli” — kısa, sinyal tabanlı.
String revenueValueExplanationShort(CustomerRevenueSignals s) {
  final parts = <String>[];
  if (s.leadScore >= 75) {
    parts.add('Lead skoru yüksek');
  } else if (s.leadScore >= 45) {
    parts.add('Lead skoru orta–üst');
  }
  if (s.band == RevenueLeadBand.hot) {
    parts.add('satın alma sıcaklığı yüksek');
  } else if (s.band == RevenueLeadBand.warm) {
    parts.add('takip ile ısıtılabilir');
  }
  if (s.valueScore >= 55) {
    parts.add('işlem potansiyeli güçlü');
  }
  if (s.syncDelayedRisk) {
    parts.add('senkron riski var; veriyi güncel tutun');
  }
  if (parts.isEmpty) {
    return 'Takip ve sıcaklık için uygun bir portföy kaydı.';
  }
  return parts.take(3).join(' · ');
}
