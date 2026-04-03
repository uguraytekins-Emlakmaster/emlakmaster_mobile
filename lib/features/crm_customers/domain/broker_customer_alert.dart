/// Broker / yönetici uyarıları — kural tabanlı, LLM yok.
library broker_customer_alert;

import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Öncelik sıralaması: high &lt; medium &lt; low (yüksek önce).
enum BrokerAlertPriority {
  high,
  medium,
  low,
}

enum BrokerAlertCode {
  highValueOpportunity,
  urgentFollowUpMissed,
  appointmentAtRisk,
  priceNegotiationActive,
  hotCustomerIdle,
}

extension BrokerAlertCodeIds on BrokerAlertCode {
  /// API / analitik için sabit snake_case kod.
  String get alertCode {
    switch (this) {
      case BrokerAlertCode.highValueOpportunity:
        return 'high_value_opportunity';
      case BrokerAlertCode.urgentFollowUpMissed:
        return 'urgent_follow_up_missed';
      case BrokerAlertCode.appointmentAtRisk:
        return 'appointment_at_risk';
      case BrokerAlertCode.priceNegotiationActive:
        return 'price_negotiation_active';
      case BrokerAlertCode.hotCustomerIdle:
        return 'hot_customer_idle';
    }
  }
}

/// Tek müşteri + tek uyarı türü satırı.
class BrokerCustomerAlertItem {
  const BrokerCustomerAlertItem({
    required this.customerId,
    required this.customerName,
    required this.code,
    required this.alertTitleTr,
    required this.alertDescriptionTr,
    required this.priorityLevel,
    this.aiInsightLineTr,
  });

  final String customerId;
  final String? customerName;
  final BrokerAlertCode code;
  final String alertTitleTr;
  final String alertDescriptionTr;
  final BrokerAlertPriority priorityLevel;
  /// `customers.lastCallAiEnrichment` — liste için önceden üretilmiş kısa satır.
  final String? aiInsightLineTr;

  int get _sortKey {
    switch (priorityLevel) {
      case BrokerAlertPriority.high:
        return 0;
      case BrokerAlertPriority.medium:
        return 1;
      case BrokerAlertPriority.low:
        return 2;
    }
  }
}

const int _daysHotIdle = 5;
const int _daysUrgentMissed = 2;
const int _daysAppointmentStale = 2;
const int _highValueHeatThreshold = 85;

/// Müşteri başına 0..N uyarı; aynı [BrokerAlertCode] en fazla bir kez.
List<BrokerCustomerAlertItem> computeBrokerAlertsForCustomer(CustomerEntity customer) {
  final heat = computeCustomerHeat(customer);
  final s = customer.lastCallSummarySignals;
  final now = DateTime.now();
  final lastInt = customer.lastInteractionAt;
  final daysSinceInteraction =
      lastInt == null ? 999 : now.difference(lastInt).inDays;

  final out = <BrokerCustomerAlertItem>[];
  final name = customer.fullName;
  final aiLine = savedAiInsightSnippetTr(customer.lastCallAiEnrichment);

  void push(
    BrokerAlertCode code,
    String title,
    String desc,
    BrokerAlertPriority p,
  ) {
    if (out.any((e) => e.code == code)) return;
    out.add(BrokerCustomerAlertItem(
      customerId: customer.id,
      customerName: name,
      code: code,
      alertTitleTr: title,
      alertDescriptionTr: desc,
      priorityLevel: p,
      aiInsightLineTr: aiLine,
    ));
  }

  if (heat.heatScore > _highValueHeatThreshold) {
    push(
      BrokerAlertCode.highValueOpportunity,
      'Yüksek değerli fırsat',
      'Sıcaklık skoru $_highValueHeatThreshold üzerinde; önceliklendirin.',
      BrokerAlertPriority.high,
    );
  }

  if (s != null &&
      s.followUpUrgency == PostCallCrmSignals.urgencyHigh &&
      (lastInt == null || daysSinceInteraction >= _daysUrgentMissed)) {
    push(
      BrokerAlertCode.urgentFollowUpMissed,
      'Acil takip kaçıyor',
      'Çağrıda acil takip işaretlendi; son günlerde yakın temas görünmüyor.',
      BrokerAlertPriority.high,
    );
  }

  if (s != null &&
      s.appointmentMentioned &&
      !s.priceObjection &&
      (lastInt == null || daysSinceInteraction > _daysAppointmentStale)) {
    push(
      BrokerAlertCode.appointmentAtRisk,
      'Randevu netleşmedi',
      'Randevu geçti ama son temas zayıf; tarih ve saati teyit edin.',
      BrokerAlertPriority.medium,
    );
  }

  if (s != null &&
      s.priceObjection &&
      s.interestLevel == PostCallCrmSignals.interestHigh) {
    push(
      BrokerAlertCode.priceNegotiationActive,
      'Aktif fiyat görüşmesi',
      'Yüksek ilgi ve fiyat itirazı birlikte; alternatif ve net rakam verin.',
      BrokerAlertPriority.medium,
    );
  }

  if (heat.heatLevel == CustomerHeatLevel.hot &&
      (lastInt == null || daysSinceInteraction >= _daysHotIdle)) {
    push(
      BrokerAlertCode.hotCustomerIdle,
      'Sıcak müşteri bekliyor',
      'Sıcaklık yüksek ama son temas $_daysHotIdle+ gün önce veya hiç yok.',
      BrokerAlertPriority.high,
    );
  }

  out.sort((a, b) {
    final c = a._sortKey.compareTo(b._sortKey);
    if (c != 0) return c;
    return a.code.name.compareTo(b.code.name);
  });
  return out;
}

/// Ofis listesi → düzleştirilmiş uyarılar (ek sorgu yok).
List<BrokerCustomerAlertItem> aggregateBrokerAlerts(
  List<CustomerEntity> customers, {
  int maxItems = 12,
}) {
  final flat = <BrokerCustomerAlertItem>[];
  for (final c in customers) {
    flat.addAll(computeBrokerAlertsForCustomer(c));
  }
  flat.sort((a, b) {
    final p = a._sortKey.compareTo(b._sortKey);
    if (p != 0) return p;
    final n = (a.customerName ?? '').compareTo(b.customerName ?? '');
    if (n != 0) return n;
    return a.code.name.compareTo(b.code.name);
  });
  if (flat.length <= maxItems) return flat;
  return flat.sublist(0, maxItems);
}

bool brokerAlertsActiveForCustomer(CustomerEntity customer) =>
    computeBrokerAlertsForCustomer(customer).isNotEmpty;
