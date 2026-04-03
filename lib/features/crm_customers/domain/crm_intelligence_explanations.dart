/// Deterministic açıklama katmanı — skor ve kurallar değişmez; yalnızca metin.
library crm_intelligence_explanations;

import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_next_best_action.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/smart_task_suggestion.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

// --- Sıcaklık ---

String explainHeatNarrative(
  CustomerEntity customer,
  CustomerHeatSnapshot heat,
  CustomerHeatExtras extras,
) {
  final s = customer.lastCallSummarySignals;
  final lastInt = customer.lastInteractionAt;
  final daysSinceInteraction =
      lastInt == null ? null : DateTime.now().difference(lastInt).inDays;

  if (s != null &&
      s.appointmentMentioned &&
      s.interestLevel == PostCallCrmSignals.interestHigh) {
    return 'Son görüşmede randevu sinyali ve yüksek ilgi tespit edildi.';
  }
  if (s != null &&
      s.priceObjection &&
      s.interestLevel == PostCallCrmSignals.interestHigh) {
    return 'Fiyat itirazı nedeniyle pazarlık takibi öneriliyor.';
  }
  if (heat.heatLevel == CustomerHeatLevel.hot &&
      daysSinceInteraction != null &&
      daysSinceInteraction >= 5) {
    return 'Müşteri sıcak ancak $daysSinceInteraction gündür temas yok.';
  }
  if (s != null &&
      s.followUpUrgency == PostCallCrmSignals.urgencyHigh &&
      s.interestLevel == PostCallCrmSignals.interestHigh) {
    return 'Son görüşmede yüksek ilgi ve acil takip sinyali birlikte geldi.';
  }
  if (s != null && s.appointmentMentioned) {
    return 'Son görüşmede randevu sinyali geçti; tarih netleşmesi faydalı.';
  }
  if (s != null && s.followUpUrgency == PostCallCrmSignals.urgencyHigh) {
    return 'Son görüşmede acil takip işaretlendi; canlı temas önerilir.';
  }
  if (extras.openTasksForCustomer >= 1) {
    return 'Açık görevlerle müşteri hâlâ aktif; takip hattı canlı.';
  }
  if (heat.heatLevel == CustomerHeatLevel.cold ||
      heat.heatLevel == CustomerHeatLevel.cool) {
    return 'Öncelik sınırlı; nazik ve aralıklı iletişim yeterli.';
  }
  if (heat.heatLevel == CustomerHeatLevel.warm) {
    return 'Ilık ilgi var; somut bir sonraki adım önerilir.';
  }
  if (heat.heatLevel == CustomerHeatLevel.hot) {
    return 'Güçlü sıcaklık; bugün veya yarın için net bir adım planlayın.';
  }
  return heat.heatReasonSummary;
}

// --- Sonraki en iyi aksiyon ---

String explainNextBestNarrative(
  NextBestActionSnapshot nba,
  CustomerHeatSnapshot heat,
) {
  switch (nba.code) {
    case NextBestActionCode.prioritize_open_tasks:
      return 'Önce bekleyen görevi tamamlamak, sonra yeni aramayı planlamak için uygun.';
    case NextBestActionCode.send_price_followup:
      return 'Fiyat ve bütçede netlik için kısa ve samimi bir dönüş planlayın.';
    case NextBestActionCode.confirm_appointment:
      return 'Randevu konuşuldu; tarih ve saati netleştirmek güven verir.';
    case NextBestActionCode.call_now:
      return 'Sinyaller canlı; kısa bir telefonla momentumu yakalayın.';
    case NextBestActionCode.wait_and_watch:
      return 'Temas taze, sıcaklık düşük; bugün için baskı yerine gözlem yeterli.';
    case NextBestActionCode.follow_up_today:
      return 'Bugün içinde kısa bir kontrol, ilişkiyi sıcak tutar.';
    case NextBestActionCode.nurture_sequence:
      return 'Uzun soluklu ilişki için aralıklı bilgi ve hatırlatma yeterli.';
    case NextBestActionCode.schedule_visit:
      return heat.heatLevel == CustomerHeatLevel.hot
          ? 'Yüz yüze veya portföy üzerinden somut bir adım zamanı.'
          : 'Somut ilan veya sunum için randevu ile ilerlemek iyi olur.';
  }
}

// --- Broker uyarıları ---

String explainBrokerAlertTitleTr(BrokerAlertCode code) {
  switch (code) {
    case BrokerAlertCode.highValueOpportunity:
      return 'Öncelikli fırsat';
    case BrokerAlertCode.urgentFollowUpMissed:
      return 'Acil takip bekliyor';
    case BrokerAlertCode.appointmentAtRisk:
      return 'Randevu netleşmeli';
    case BrokerAlertCode.priceNegotiationActive:
      return 'Aktif pazarlık';
    case BrokerAlertCode.hotCustomerIdle:
      return 'Sıcak müşteri sessiz';
  }
}

String explainBrokerAlertDescriptionTr(BrokerAlertCode code) {
  switch (code) {
    case BrokerAlertCode.highValueOpportunity:
      return 'Skor çok yüksek; bu müşteriyi bugün öne almak mantıklı.';
    case BrokerAlertCode.urgentFollowUpMissed:
      return 'Son görüşmede acil takip işaretlendi; yakın temas bekleniyor.';
    case BrokerAlertCode.appointmentAtRisk:
      return 'Randevu konuşuldu ama henüz teyit yok; tarih netleşmeli.';
    case BrokerAlertCode.priceNegotiationActive:
      return 'Yüksek ilgi ve fiyat itirazı birlikte; alternatif sunmak iyi olur.';
    case BrokerAlertCode.hotCustomerIdle:
      return 'Sıcaklık yüksek ama son temas uzun süre önce; hatırlatın.';
  }
}

// --- Akıllı görev önerisi ---

String explainSmartTaskNarrative(TaskSuggestionCode code) {
  switch (code) {
    case TaskSuggestionCode.urgentFollowUpCall:
      return 'Acil takip sinyali için atanmış bir görev, ekibin takvimine netlik katar.';
    case TaskSuggestionCode.appointmentConfirmation:
      return 'Randevuyu yazılı göreve bağlamak, kaçırılan detayları azaltır.';
    case TaskSuggestionCode.pricingFollowUp:
      return 'Fiyat görüşmesini göreve dökmek, takipte sorumluluk netleşir.';
    case TaskSuggestionCode.immediateCall:
      return 'Sıcak lead için kısa arama görevi, momentumu korumanın en temiz yolu.';
    case TaskSuggestionCode.highValueTouchpoint:
      return 'Yüksek değerli müşteride üst düzey teması görevle sabitleyin.';
  }
}
