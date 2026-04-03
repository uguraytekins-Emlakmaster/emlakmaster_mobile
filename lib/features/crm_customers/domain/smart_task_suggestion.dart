/// Kural tabanlı görev önerisi — Firestore’a sessiz yazım yok; kullanıcı onayı gerekir.
library smart_task_suggestion;

import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart'
    show BrokerAlertCode, BrokerCustomerAlertItem, computeBrokerAlertsForCustomer;
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

enum TaskSuggestionCode {
  urgentFollowUpCall,
  appointmentConfirmation,
  pricingFollowUp,
  immediateCall,
  highValueTouchpoint,
}

extension TaskSuggestionCodeIds on TaskSuggestionCode {
  String get taskSuggestionCode {
    switch (this) {
      case TaskSuggestionCode.urgentFollowUpCall:
        return 'urgent_follow_up_call';
      case TaskSuggestionCode.appointmentConfirmation:
        return 'appointment_confirmation';
      case TaskSuggestionCode.pricingFollowUp:
        return 'pricing_follow_up';
      case TaskSuggestionCode.immediateCall:
        return 'immediate_call';
      case TaskSuggestionCode.highValueTouchpoint:
        return 'high_value_touchpoint';
    }
  }
}

enum TaskSuggestionUrgency {
  high,
  medium,
  low,
}

/// Broker uyarısı + müşteri bağlamı → tek görev önerisi.
class SmartTaskSuggestion {
  const SmartTaskSuggestion({
    required this.code,
    required this.taskSuggestionLabelTr,
    required this.taskSuggestionReasonTr,
    required this.suggestedDueAt,
    required this.urgency,
    required this.relatedCustomerId,
    required this.customerName,
    required this.assigneeAdvisorId,
    required this.sourceAlertCode,
  });

  final TaskSuggestionCode code;
  final String taskSuggestionLabelTr;
  final String taskSuggestionReasonTr;
  final DateTime suggestedDueAt;
  final TaskSuggestionUrgency urgency;
  final String relatedCustomerId;
  final String? customerName;
  /// Görevin atanacağı danışman (müşteri `assignedAdvisorId` veya broker kendisi).
  final String assigneeAdvisorId;
  final BrokerAlertCode sourceAlertCode;

  String get dedupeKey => '$relatedCustomerId|${code.taskSuggestionCode}';

  /// Firestore `tasks` başlığı (kısa).
  String get titleForFirestore {
    final n = (customerName ?? 'Müşteri').trim();
    switch (code) {
      case TaskSuggestionCode.urgentFollowUpCall:
        return 'Acil takip: $n';
      case TaskSuggestionCode.appointmentConfirmation:
        return 'Randevu teyidi: $n';
      case TaskSuggestionCode.pricingFollowUp:
        return 'Fiyat / bütçe takibi: $n';
      case TaskSuggestionCode.immediateCall:
        return 'Arama (sıcak lead): $n';
      case TaskSuggestionCode.highValueTouchpoint:
        return 'Öncelikli temas: $n';
    }
  }
}

DateTime _endOfTodayLocal() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, 23, 59);
}

DateTime _hoursFromNow(int h) => DateTime.now().add(Duration(hours: h));

DateTime _daysFromNowAt(int days, int hour, int minute) {
  final n = DateTime.now().add(Duration(days: days));
  return DateTime(n.year, n.month, n.day, hour, minute);
}

/// [BrokerCustomerAlertItem] + tam [CustomerEntity] (atama için).
SmartTaskSuggestion smartTaskSuggestionFromAlert(
  BrokerCustomerAlertItem alert,
  CustomerEntity customer,
  String fallbackAdvisorId,
) {
  final assignee = (customer.assignedAdvisorId != null &&
          customer.assignedAdvisorId!.trim().isNotEmpty)
      ? customer.assignedAdvisorId!.trim()
      : fallbackAdvisorId;

  switch (alert.code) {
    case BrokerAlertCode.urgentFollowUpMissed:
      return SmartTaskSuggestion(
        code: TaskSuggestionCode.urgentFollowUpCall,
        taskSuggestionLabelTr: 'Acil takip araması',
        taskSuggestionReasonTr:
            'Çağrıda acil takip sinyali var; danışmana atanmış görev olarak kaydedin.',
        suggestedDueAt: _hoursFromNow(4),
        urgency: TaskSuggestionUrgency.high,
        relatedCustomerId: customer.id,
        customerName: customer.fullName,
        assigneeAdvisorId: assignee,
        sourceAlertCode: alert.code,
      );
    case BrokerAlertCode.appointmentAtRisk:
      return SmartTaskSuggestion(
        code: TaskSuggestionCode.appointmentConfirmation,
        taskSuggestionLabelTr: 'Randevu teyidi',
        taskSuggestionReasonTr:
            'Randevu geçmiş; tarih ve saati netleştirmek için görev oluşturun.',
        suggestedDueAt: _daysFromNowAt(1, 17, 0),
        urgency: TaskSuggestionUrgency.medium,
        relatedCustomerId: customer.id,
        customerName: customer.fullName,
        assigneeAdvisorId: assignee,
        sourceAlertCode: alert.code,
      );
    case BrokerAlertCode.priceNegotiationActive:
      return SmartTaskSuggestion(
        code: TaskSuggestionCode.pricingFollowUp,
        taskSuggestionLabelTr: 'Fiyat / bütçe takibi',
        taskSuggestionReasonTr:
            'Yüksek ilgi ve fiyat itirazı; alternatif ve rakam için takip görevi.',
        suggestedDueAt: _daysFromNowAt(2, 12, 0),
        urgency: TaskSuggestionUrgency.medium,
        relatedCustomerId: customer.id,
        customerName: customer.fullName,
        assigneeAdvisorId: assignee,
        sourceAlertCode: alert.code,
      );
    case BrokerAlertCode.hotCustomerIdle:
      return SmartTaskSuggestion(
        code: TaskSuggestionCode.immediateCall,
        taskSuggestionLabelTr: 'Kısa arama',
        taskSuggestionReasonTr:
            'Sıcaklık yüksek ama temas gecikmiş; bugün arama görevi önerilir.',
        suggestedDueAt: _endOfTodayLocal(),
        urgency: TaskSuggestionUrgency.high,
        relatedCustomerId: customer.id,
        customerName: customer.fullName,
        assigneeAdvisorId: assignee,
        sourceAlertCode: alert.code,
      );
    case BrokerAlertCode.highValueOpportunity:
      return SmartTaskSuggestion(
        code: TaskSuggestionCode.highValueTouchpoint,
        taskSuggestionLabelTr: 'Öncelikli temas',
        taskSuggestionReasonTr:
            'Sıcaklık skoru çok yüksek; üst düzey takip veya yüz yüze adımı için görev.',
        suggestedDueAt: _daysFromNowAt(1, 11, 0),
        urgency: TaskSuggestionUrgency.high,
        relatedCustomerId: customer.id,
        customerName: customer.fullName,
        assigneeAdvisorId: assignee,
        sourceAlertCode: alert.code,
      );
  }
}

int _urgencySort(TaskSuggestionUrgency u) {
  switch (u) {
    case TaskSuggestionUrgency.high:
      return 0;
    case TaskSuggestionUrgency.medium:
      return 1;
    case TaskSuggestionUrgency.low:
      return 2;
  }
}

/// Ofis müşteri listesi → öneriler (ek sorgu yok; uyarı kuralları ile hizalı).
List<SmartTaskSuggestion> aggregateSmartTaskSuggestions(
  List<CustomerEntity> customers, {
  String fallbackAdvisorId = '',
  int maxItems = 12,
}) {
  final flat = <SmartTaskSuggestion>[];
  for (final c in customers) {
    for (final a in computeBrokerAlertsForCustomer(c)) {
      flat.add(smartTaskSuggestionFromAlert(a, c, fallbackAdvisorId));
    }
  }
  flat.sort((a, b) {
    final u = _urgencySort(a.urgency).compareTo(_urgencySort(b.urgency));
    if (u != 0) return u;
    final n = (a.customerName ?? '').compareTo(b.customerName ?? '');
    if (n != 0) return n;
    return a.code.name.compareTo(b.code.name);
  });
  if (flat.length <= maxItems) return flat;
  return flat.sublist(0, maxItems);
}
