/// İcra odaklı hatırlatıcılar — uyarı/öneri motoruna dokunmaz; üst katman.
library execution_reminder;

import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_next_best_action.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

enum ExecutionReminderPriority {
  critical,
  high,
  medium,
}

enum ExecutionReminderCode {
  managerEscalationFollowUp,
  overdueUrgentFollowUp,
  appointmentConfirmationReminder,
  priceNegotiationReminder,
  dueTodayFollowUp,
}

extension ExecutionReminderCodeIds on ExecutionReminderCode {
  String get reminderCode {
    switch (this) {
      case ExecutionReminderCode.managerEscalationFollowUp:
        return 'manager_escalation_reminder';
      case ExecutionReminderCode.overdueUrgentFollowUp:
        return 'overdue_urgent_follow_up';
      case ExecutionReminderCode.appointmentConfirmationReminder:
        return 'appointment_confirmation_reminder';
      case ExecutionReminderCode.priceNegotiationReminder:
        return 'price_negotiation_reminder';
      case ExecutionReminderCode.dueTodayFollowUp:
        return 'due_today_follow_up';
    }
  }
}

/// Bir sonraki adım (UI / yönlendirme).
enum SuggestedActionCode {
  openCustomer,
  createTask,
  startCall,
  confirmFollowUp,
}

extension SuggestedActionCodeIds on SuggestedActionCode {
  String get suggestedActionCode {
    switch (this) {
      case SuggestedActionCode.openCustomer:
        return 'open_customer';
      case SuggestedActionCode.createTask:
        return 'create_task';
      case SuggestedActionCode.startCall:
        return 'start_call';
      case SuggestedActionCode.confirmFollowUp:
        return 'confirm_follow_up';
    }
  }
}

class ExecutionReminderItem {
  const ExecutionReminderItem({
    required this.code,
    required this.reminderTitleTr,
    required this.reminderDescriptionTr,
    required this.reminderPriority,
    required this.relatedCustomerId,
    required this.customerName,
    required this.suggestedActionCode,
    this.assigneeAdvisorId,
  });

  final ExecutionReminderCode code;
  final String reminderTitleTr;
  final String reminderDescriptionTr;
  final ExecutionReminderPriority reminderPriority;
  final String relatedCustomerId;
  final String? customerName;
  final SuggestedActionCode suggestedActionCode;
  /// Görev oluştururken; boşsa mevcut kullanıcı.
  final String? assigneeAdvisorId;

  String get dedupeKey => '$relatedCustomerId|${code.reminderCode}';

  int get _sortKey {
    switch (reminderPriority) {
      case ExecutionReminderPriority.critical:
        return 0;
      case ExecutionReminderPriority.high:
        return 1;
      case ExecutionReminderPriority.medium:
        return 2;
    }
  }
}

int _prioritySort(ExecutionReminderPriority p) {
  switch (p) {
    case ExecutionReminderPriority.critical:
      return 0;
    case ExecutionReminderPriority.high:
      return 1;
    case ExecutionReminderPriority.medium:
      return 2;
  }
}

/// Müşteri başına en fazla 2 hatırlatıcı (öncelik sırası).
List<ExecutionReminderItem> computeExecutionRemindersForCustomer(CustomerEntity customer) {
  final heat = computeCustomerHeat(customer);
  final nba = computeNextBestAction(customer, heat: heat);
  final s = customer.lastCallSummarySignals;
  final now = DateTime.now();
  final lastInt = customer.lastInteractionAt;
  final daysSinceInteraction =
      lastInt == null ? 999 : now.difference(lastInt).inDays;

  final escalations = computeEscalationsForCustomer(customer);
  final out = <ExecutionReminderItem>[];
  final name = customer.fullName;
  final advisor = customer.assignedAdvisorId?.trim();
  final assignee = (advisor != null && advisor.isNotEmpty) ? advisor : null;

  void push(ExecutionReminderItem item) {
    if (out.any((e) => e.code == item.code)) return;
    out.add(item);
  }

  if (escalations.isNotEmpty) {
    push(
      ExecutionReminderItem(
        code: ExecutionReminderCode.managerEscalationFollowUp,
        reminderTitleTr: 'Yönetici taşıması — aksiyon',
        reminderDescriptionTr:
            'Bu müşteri yönetim önceliği listesinde; bugün net bir adım atın.',
        reminderPriority: ExecutionReminderPriority.critical,
        relatedCustomerId: customer.id,
        customerName: name,
        suggestedActionCode: SuggestedActionCode.openCustomer,
        assigneeAdvisorId: assignee,
      ),
    );
  }

  if (s != null &&
      s.followUpUrgency == PostCallCrmSignals.urgencyHigh &&
      daysSinceInteraction >= 2) {
    push(
      ExecutionReminderItem(
        code: ExecutionReminderCode.overdueUrgentFollowUp,
        reminderTitleTr: 'Acil takip gecikti',
        reminderDescriptionTr:
            'Son görüşmede acil işaretlendi; canlı temas veya görev önerilir.',
        reminderPriority: ExecutionReminderPriority.critical,
        relatedCustomerId: customer.id,
        customerName: name,
        suggestedActionCode: SuggestedActionCode.startCall,
        assigneeAdvisorId: assignee,
      ),
    );
  }

  if (s != null &&
      s.appointmentMentioned &&
      daysSinceInteraction > 2) {
    push(
      ExecutionReminderItem(
        code: ExecutionReminderCode.appointmentConfirmationReminder,
        reminderTitleTr: 'Randevu teyidi',
        reminderDescriptionTr:
            'Randevu konuşuldu; tarih ve saati netleştirmek için dönün.',
        reminderPriority: ExecutionReminderPriority.high,
        relatedCustomerId: customer.id,
        customerName: name,
        suggestedActionCode: SuggestedActionCode.createTask,
        assigneeAdvisorId: assignee,
      ),
    );
  }

  if (s != null &&
      s.priceObjection &&
      s.interestLevel == PostCallCrmSignals.interestHigh) {
    push(
      ExecutionReminderItem(
        code: ExecutionReminderCode.priceNegotiationReminder,
        reminderTitleTr: 'Fiyat görüşmesi',
        reminderDescriptionTr:
            'Yüksek ilgi ve fiyat hassasiyeti; alternatif ve rakam paylaşın.',
        reminderPriority: ExecutionReminderPriority.high,
        relatedCustomerId: customer.id,
        customerName: name,
        suggestedActionCode: SuggestedActionCode.createTask,
        assigneeAdvisorId: assignee,
      ),
    );
  }

  final dueToday = nba.code == NextBestActionCode.follow_up_today ||
      nba.code == NextBestActionCode.call_now ||
      (heat.heatLevel == CustomerHeatLevel.hot && daysSinceInteraction >= 5);

  if (dueToday && out.length < 2) {
    push(
      ExecutionReminderItem(
        code: ExecutionReminderCode.dueTodayFollowUp,
        reminderTitleTr: 'Bugün takip',
        reminderDescriptionTr:
            'Önerilen aksiyon bugün için; kısa bir arama veya mesaj yeterli.',
        reminderPriority: ExecutionReminderPriority.high,
        relatedCustomerId: customer.id,
        customerName: name,
        suggestedActionCode: SuggestedActionCode.confirmFollowUp,
        assigneeAdvisorId: assignee,
      ),
    );
  }

  out.sort((a, b) {
    final c = a._sortKey.compareTo(b._sortKey);
    if (c != 0) return c;
    return a.code.name.compareTo(b.code.name);
  });

  if (out.length <= 2) return out;
  return out.sublist(0, 2);
}

/// Liste ekranı: düzleştirilmiş hatırlatıcılar.
List<ExecutionReminderItem> aggregateExecutionReminders(
  List<CustomerEntity> customers, {
  int maxItems = 14,
  bool teamScope = false,
}) {
  final flat = <ExecutionReminderItem>[];
  for (final c in customers) {
    for (final r in computeExecutionRemindersForCustomer(c)) {
      if (teamScope &&
          r.reminderPriority == ExecutionReminderPriority.medium) {
        continue;
      }
      flat.add(r);
    }
  }
  flat.sort((a, b) {
    final p = _prioritySort(a.reminderPriority)
        .compareTo(_prioritySort(b.reminderPriority));
    if (p != 0) return p;
    final n = (a.customerName ?? '').compareTo(b.customerName ?? '');
    if (n != 0) return n;
    return a.code.name.compareTo(b.code.name);
  });
  if (flat.length <= maxItems) return flat;
  return flat.sublist(0, maxItems);
}
