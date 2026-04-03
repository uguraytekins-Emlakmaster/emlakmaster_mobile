/// Deterministic müşteri sıcaklık skoru — LLM yok; CRM + sinyal verisi.
library customer_heat_score;

import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// hot ≥ 72, warm ≥ 48, cool ≥ 24, else cold
enum CustomerHeatLevel {
  hot,
  warm,
  cool,
  cold,
}

/// Tek seferlik skor çıktısı (UI + önceliklendirme).
class CustomerHeatSnapshot {
  const CustomerHeatSnapshot({
    required this.heatScore,
    required this.heatLevel,
    required this.heatReasonSummary,
  });

  final int heatScore;
  final CustomerHeatLevel heatLevel;
  /// Kısa Türkçe, en fazla ~80 karakter
  final String heatReasonSummary;

  static CustomerHeatSnapshot empty() => const CustomerHeatSnapshot(
        heatScore: 0,
        heatLevel: CustomerHeatLevel.cold,
        heatReasonSummary: 'Henüz yeterli sinyal yok',
      );
}

/// [computeCustomerHeat] için opsiyonel bağlam (görev / not).
class CustomerHeatExtras {
  const CustomerHeatExtras({
    this.openTasksForCustomer = 0,
    this.notesLast30Days = 0,
  });

  final int openTasksForCustomer;
  final int notesLast30Days;
}

/// Kural tabanlı 0–100 skor; aynı girdide her zaman aynı çıktı.
CustomerHeatSnapshot computeCustomerHeat(
  CustomerEntity customer, {
  CustomerHeatExtras extras = const CustomerHeatExtras(),
}) {
  final now = DateTime.now();
  final reasons = <String>[];
  var raw = 0;

  final s = customer.lastCallSummarySignals;
  if (s != null) {
    switch (s.interestLevel) {
      case PostCallCrmSignals.interestHigh:
        raw += 18;
        reasons.add('Yüksek ilgi');
        break;
      case PostCallCrmSignals.interestMedium:
        raw += 10;
        reasons.add('Orta ilgi');
        break;
      case PostCallCrmSignals.interestLow:
        raw += 3;
        break;
      default:
        break;
    }
    switch (s.followUpUrgency) {
      case PostCallCrmSignals.urgencyHigh:
        raw += 22;
        reasons.add('Acil takip');
        break;
      case PostCallCrmSignals.urgencyMedium:
        raw += 12;
        reasons.add('Yakın takip');
        break;
      case PostCallCrmSignals.urgencyLow:
        raw += 4;
        break;
      default:
        break;
    }
    if (s.appointmentMentioned) {
      raw += 12;
      reasons.add('Randevu sinyali');
    }
    if (s.priceObjection) {
      raw += 8;
      reasons.add('Fiyat görüşmesi');
    }
  }

  final daysSinceUpdate = now.difference(customer.updatedAt).inDays;
  if (daysSinceUpdate <= 3) {
    raw += 10;
    if (reasons.length < 4) reasons.add('Güncel kayıt');
  } else if (daysSinceUpdate <= 10) {
    raw += 6;
  } else if (daysSinceUpdate <= 30) {
    raw += 3;
  }

  final lastInt = customer.lastInteractionAt;
  if (lastInt != null) {
    final d = now.difference(lastInt).inDays;
    if (d <= 7) {
      raw += 8;
      if (reasons.length < 4) reasons.add('Son temas yakın');
    } else if (d <= 21) {
      raw += 4;
    }
  }

  raw += (customer.callsCount * 2).clamp(0, 8);
  if (customer.callsCount > 0 && reasons.length < 4) {
    reasons.add('Çağrı geçmişi');
  }
  raw += (customer.visitsCount * 3).clamp(0, 6);
  raw += (customer.offersCount * 4).clamp(0, 8);

  final lt = customer.leadTemperature;
  if (lt != null && lt > 0) {
    raw += (lt * 2).round().clamp(0, 10);
  }

  final t = extras.openTasksForCustomer;
  if (t > 0) {
    raw += (t * 4).clamp(0, 12);
    reasons.add('Açık görev');
  }

  final n = extras.notesLast30Days;
  if (n > 0) {
    raw += (n * 2).clamp(0, 10);
    if (reasons.length < 5 && n >= 2) reasons.add('Aktif not trafiği');
  }

  if (customer.isVipInvestor) {
    raw += 6;
    if (reasons.length < 5) reasons.add('VIP yatırımcı');
  }

  final score = raw.clamp(0, 100);
  final level = _levelFor(score);
  var summary = reasons.isNotEmpty ? reasons.take(3).join(' · ') : _defaultSummary(level, s != null);
  if (summary.length > 90) {
    summary = '${summary.substring(0, 87)}…';
  }

  return CustomerHeatSnapshot(
    heatScore: score,
    heatLevel: level,
    heatReasonSummary: summary,
  );
}

CustomerHeatLevel _levelFor(int score) {
  if (score >= 72) return CustomerHeatLevel.hot;
  if (score >= 48) return CustomerHeatLevel.warm;
  if (score >= 24) return CustomerHeatLevel.cool;
  return CustomerHeatLevel.cold;
}

String _defaultSummary(CustomerHeatLevel level, bool hadSignals) {
  switch (level) {
    case CustomerHeatLevel.hot:
      return hadSignals ? 'Güçlü sinyal ve etkileşim' : 'Yüksek etkileşim';
    case CustomerHeatLevel.warm:
      return 'Takip için uygun';
    case CustomerHeatLevel.cool:
      return 'Nazik takip önerilir';
    case CustomerHeatLevel.cold:
      return 'Henüz yeterli sinyal yok';
  }
}

String heatLevelLabelTr(CustomerHeatLevel level) {
  switch (level) {
    case CustomerHeatLevel.hot:
      return 'Sıcak';
    case CustomerHeatLevel.warm:
      return 'Ilık';
    case CustomerHeatLevel.cool:
      return 'Soğuk';
    case CustomerHeatLevel.cold:
      return 'Durgun';
  }
}
