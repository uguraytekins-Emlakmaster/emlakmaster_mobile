/// Yönetici taşıması — kural tabanlı; broker uyarılarından daha seçici.
library manager_escalation;

import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

enum EscalationPriority {
  critical,
  high,
  medium,
}

enum EscalationCode {
  multipleCriticalSignals,
  hotNeglected,
  urgentAging,
  appointmentSlipping,
  priceNegotiationPriority,
}

extension EscalationCodeIds on EscalationCode {
  String get escalationCode {
    switch (this) {
      case EscalationCode.multipleCriticalSignals:
        return 'multiple_critical_signals';
      case EscalationCode.hotNeglected:
        return 'hot_neglected';
      case EscalationCode.urgentAging:
        return 'urgent_aging';
      case EscalationCode.appointmentSlipping:
        return 'appointment_slipping';
      case EscalationCode.priceNegotiationPriority:
        return 'price_negotiation_priority';
    }
  }
}

class ManagerEscalationItem {
  const ManagerEscalationItem({
    required this.code,
    required this.escalationTitleTr,
    required this.escalationDescriptionTr,
    required this.escalationPriority,
    required this.relatedCustomerId,
    required this.customerName,
    this.aiInsightLineTr,
  });

  final EscalationCode code;
  final String escalationTitleTr;
  final String escalationDescriptionTr;
  final EscalationPriority escalationPriority;
  final String relatedCustomerId;
  final String? customerName;
  final String? aiInsightLineTr;

  String get dedupeKey => '$relatedCustomerId|${code.escalationCode}';

  int get _sortKey {
    switch (escalationPriority) {
      case EscalationPriority.critical:
        return 0;
      case EscalationPriority.high:
        return 1;
      case EscalationPriority.medium:
        return 2;
    }
  }
}

const int _daysHotNeglected = 7;
const int _daysUrgentAging = 3;
const int _daysAppointmentSlip = 3;

int _prioritySort(EscalationPriority p) {
  switch (p) {
    case EscalationPriority.critical:
      return 0;
    case EscalationPriority.high:
      return 1;
    case EscalationPriority.medium:
      return 2;
  }
}

/// Müşteri başına 0..N kural; birincil seçimde en yüksek öncelik kullanılır.
List<ManagerEscalationItem> computeEscalationsForCustomer(CustomerEntity customer) {
  final heat = computeCustomerHeat(customer);
  final s = customer.lastCallSummarySignals;
  final now = DateTime.now();
  final lastInt = customer.lastInteractionAt;
  final daysSinceInteraction =
      lastInt == null ? 999 : now.difference(lastInt).inDays;

  final brokerAlerts = computeBrokerAlertsForCustomer(customer);
  final out = <ManagerEscalationItem>[];
  final name = customer.fullName;
  final aiLine = savedAiInsightSnippetTr(customer.lastCallAiEnrichment);

  void push(
    EscalationCode code,
    String title,
    String desc,
    EscalationPriority p,
  ) {
    if (out.any((e) => e.code == code)) return;
    out.add(ManagerEscalationItem(
      code: code,
      escalationTitleTr: title,
      escalationDescriptionTr: desc,
      escalationPriority: p,
      relatedCustomerId: customer.id,
      customerName: name,
      aiInsightLineTr: aiLine,
    ));
  }

  if (brokerAlerts.length >= 2) {
    push(
      EscalationCode.multipleCriticalSignals,
      'Üst üste kritik sinyaller',
      'Bu müşteride aynı anda birden fazla risk işareti var; yönetim gözü önerilir.',
      EscalationPriority.critical,
    );
  }

  if (s != null &&
      s.priceObjection &&
      s.interestLevel == PostCallCrmSignals.interestHigh) {
    push(
      EscalationCode.priceNegotiationPriority,
      'Pazarlıkta kritik fırsat',
      'Yüksek ilgi ve fiyat hassasiyeti bir arada; üst düzey müdahale zamanı.',
      EscalationPriority.critical,
    );
  }

  if (heat.heatLevel == CustomerHeatLevel.hot &&
      (lastInt == null || daysSinceInteraction >= _daysHotNeglected)) {
    push(
      EscalationCode.hotNeglected,
      'Sıcak müşteri ihmal riski',
      'Sıcaklık yüksek ama temas uzun süredir yok; ekip koordinasyonu gerekebilir.',
      EscalationPriority.critical,
    );
  }

  if (s != null &&
      s.followUpUrgency == PostCallCrmSignals.urgencyHigh &&
      daysSinceInteraction >= _daysUrgentAging) {
    push(
      EscalationCode.urgentAging,
      'Acil takip bekliyor',
      'Acil işaretlendi; son temas $_daysUrgentAging günden eski.',
      EscalationPriority.high,
    );
  }

  if (s != null &&
      s.appointmentMentioned &&
      !s.priceObjection &&
      daysSinceInteraction > _daysAppointmentSlip) {
    push(
      EscalationCode.appointmentSlipping,
      'Randevu netleşmiyor',
      'Randevu konuşuldu ama takip zayıf; yönetici teyidi faydalı olabilir.',
      EscalationPriority.high,
    );
  }

  out.sort((a, b) {
    final c = a._sortKey.compareTo(b._sortKey);
    if (c != 0) return c;
    return a.code.name.compareTo(b.code.name);
  });
  return out;
}

/// Gürültü kontrolü: müşteri başına tek birincil taşıma (en yüksek öncelik).
List<ManagerEscalationItem> aggregatePrimaryEscalations(
  List<CustomerEntity> customers, {
  int maxItems = 8,
}) {
  final out = <ManagerEscalationItem>[];
  for (final c in customers) {
    final list = computeEscalationsForCustomer(c);
    if (list.isEmpty) continue;
    out.add(list.first);
  }
  out.sort((a, b) {
    final p = _prioritySort(a.escalationPriority)
        .compareTo(_prioritySort(b.escalationPriority));
    if (p != 0) return p;
    final n = (a.customerName ?? '').compareTo(b.customerName ?? '');
    if (n != 0) return n;
    return a.code.name.compareTo(b.code.name);
  });
  if (out.length <= maxItems) return out;
  return out.sublist(0, maxItems);
}

bool managerEscalationActiveForCustomer(CustomerEntity customer) =>
    computeEscalationsForCustomer(customer).isNotEmpty;
