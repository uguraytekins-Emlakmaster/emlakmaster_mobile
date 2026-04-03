/// Kural tabanlı sonraki en iyi aksiyon — LLM yok.
library customer_next_best_action;

import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

enum NextBestActionCode {
  call_now,
  schedule_visit,
  confirm_appointment,
  send_price_followup,
  follow_up_today,
  nurture_sequence,
  wait_and_watch,
  prioritize_open_tasks,
}

class NextBestActionSnapshot {
  const NextBestActionSnapshot({
    required this.code,
    required this.labelTr,
    required this.reasonTr,
  });

  final NextBestActionCode code;
  final String labelTr;
  final String reasonTr;

  static NextBestActionSnapshot fallback() => const NextBestActionSnapshot(
        code: NextBestActionCode.follow_up_today,
        labelTr: 'Bugün kısa takip',
        reasonTr: 'Genel takip zamanlaması için uygun.',
      );
}

/// [heat] ve [extras] ile tutarlı, açıklanabilir öneri (öncelik sırası sabit).
NextBestActionSnapshot computeNextBestAction(
  CustomerEntity customer, {
  required CustomerHeatSnapshot heat,
  CustomerHeatExtras extras = const CustomerHeatExtras(),
}) {
  final now = DateTime.now();
  final s = customer.lastCallSummarySignals;
  final daysSinceUpdate = now.difference(customer.updatedAt).inDays;
  final lastInt = customer.lastInteractionAt;
  final daysSinceInteraction = lastInt == null ? 999 : now.difference(lastInt).inDays;

  if (extras.openTasksForCustomer >= 1) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.prioritize_open_tasks,
      labelTr: 'Önce görevleri kapatın',
      reasonTr: 'Bu müşteri için açık görev var; önce tamamlayın, sonra arama planlayın.',
    );
  }

  if (s != null && s.priceObjection) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.send_price_followup,
      labelTr: 'Fiyat / bütçe takibi',
      reasonTr: 'Fiyat veya bütçe itirazı sinyali var; alternatif ve net rakam paylaşın.',
    );
  }

  if (s != null && s.appointmentMentioned) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.confirm_appointment,
      labelTr: 'Randevuyu netleştirin',
      reasonTr: 'Görüşme veya randevu geçti; tarih ve saati teyit edin.',
    );
  }

  if (s != null &&
      s.followUpUrgency == PostCallCrmSignals.urgencyHigh &&
      s.interestLevel == PostCallCrmSignals.interestHigh) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.call_now,
      labelTr: 'Şimdi arayın',
      reasonTr: 'Yüksek ilgi ve acil takip sinyali birlikte; kısa sürede canlı temas önerilir.',
    );
  }

  if (s != null && s.followUpUrgency == PostCallCrmSignals.urgencyHigh) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.call_now,
      labelTr: 'Öncelikli arama',
      reasonTr: 'Takip aciliyeti yüksek; bugün içinde dönüş planlayın.',
    );
  }

  if ((heat.heatLevel == CustomerHeatLevel.cold || heat.heatLevel == CustomerHeatLevel.cool) &&
      daysSinceUpdate <= 3 &&
      daysSinceInteraction <= 5) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.wait_and_watch,
      labelTr: 'Kısa süre bekleyin',
      reasonTr: 'Sıcaklık düşük ama temas taze; agresif baskıdan kaçının, gözlemleyin.',
    );
  }

  if (heat.heatLevel == CustomerHeatLevel.warm &&
      (daysSinceInteraction > 10 || extras.notesLast30Days == 0)) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.follow_up_today,
      labelTr: 'Bugün takip araması',
      reasonTr: 'Ilık lead ve etkileşim veya not trafiği zayıf; kısa bir kontrol araması uygun.',
    );
  }

  if (heat.heatLevel == CustomerHeatLevel.hot && daysSinceInteraction > 5) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.follow_up_today,
      labelTr: 'Bugün yakın takip',
      reasonTr: 'Sıcaklık yüksek ama son temas birkaç gün önce; momentumu koruyun.',
    );
  }

  if (heat.heatLevel == CustomerHeatLevel.cold || heat.heatLevel == CustomerHeatLevel.cool) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.nurture_sequence,
      labelTr: 'Uzun vadeli besleme',
      reasonTr: 'Öncelik düşük; periyodik bilgi ve hatırlatma ile ilişkiyi sürdürün.',
    );
  }

  if (heat.heatLevel == CustomerHeatLevel.hot) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.schedule_visit,
      labelTr: 'Yüz yüze görüşme planı',
      reasonTr: 'Güçlü sıcaklık; ofis veya portföy üzerinden yüz yüze adımı önerin.',
    );
  }

  if (heat.heatLevel == CustomerHeatLevel.warm) {
    return const NextBestActionSnapshot(
      code: NextBestActionCode.schedule_visit,
      labelTr: 'Görüşme veya sunum',
      reasonTr: 'Ilık lead; somut ilan veya sunum için randevu önerin.',
    );
  }

  return NextBestActionSnapshot.fallback();
}

/// Liste ekranları: ek sorgu yok; heat entity-only ile tutarlı NBA.
NextBestActionSnapshot computeNextBestActionForList(CustomerEntity customer) {
  final heat = computeCustomerHeat(customer);
  return computeNextBestAction(customer, heat: heat);
}
