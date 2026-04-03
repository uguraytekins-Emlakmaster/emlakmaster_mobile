/// Broker / yönetici dashboard — tek bakışta operasyon özeti (mevcut listelerden türetilir).
library broker_dashboard_intelligence_summary;

import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/execution_reminder.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/smart_task_suggestion.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Kısa satırlar: Son · Kritik · Sonraki · Takım odağı
class BrokerDashboardIntelligenceLines {
  const BrokerDashboardIntelligenceLines({
    this.recentLine,
    this.criticalLine,
    this.nextLine,
    this.teamFocusLine,
  });

  final String? recentLine;
  final String? criticalLine;
  final String? nextLine;
  final String? teamFocusLine;

  static const BrokerDashboardIntelligenceLines empty = BrokerDashboardIntelligenceLines();

  bool get hasAny =>
      _nonEmpty(recentLine) ||
      _nonEmpty(criticalLine) ||
      _nonEmpty(nextLine) ||
      _nonEmpty(teamFocusLine);

  static bool _nonEmpty(String? s) => s != null && s.trim().isNotEmpty;
}

BrokerDashboardIntelligenceLines buildBrokerDashboardIntelligenceSummary({
  required List<BrokerCustomerAlertItem> alerts,
  required List<ManagerEscalationItem> escalations,
  required List<SmartTaskSuggestion> smartTasks,
  required List<ExecutionReminderItem> executionReminders,
  required List<CustomerEntity> customers,
}) {
  final highAlerts = alerts.where((a) => a.priorityLevel == BrokerAlertPriority.high).length;
  final priorityCustomers = customers
      .where(
        (c) =>
            c.lastCallSummarySignals != null &&
            postCallSignalsIsPriority(c.lastCallSummarySignals!),
      )
      .length;

  final escCrit =
      escalations.where((e) => e.escalationPriority == EscalationPriority.critical).length;
  final escHigh =
      escalations.where((e) => e.escalationPriority == EscalationPriority.high).length;
  final remCrit =
      executionReminders.where((r) => r.reminderPriority == ExecutionReminderPriority.critical).length;
  final remHigh =
      executionReminders.where((r) => r.reminderPriority == ExecutionReminderPriority.high).length;

  final recent = alerts.isEmpty
      ? 'Son tarama: ofis uyarısı yok; liste güncel.'
      : 'Son tarama: ${alerts.length} ofis uyarısı${highAlerts > 0 ? ' ($highAlerts yüksek öncelik)' : ''}.';

  final critical = _lineCritical(
    escalations.length,
    escCrit,
    escHigh,
    remCrit,
    remHigh,
    priorityCustomers,
  );

  final next = _lineNext(escalations, smartTasks, executionReminders);

  final team = _lineTeamFocus(
    priorityCustomers,
    executionReminders.length,
    smartTasks.length,
    alerts.length,
  );

  final allQuiet = alerts.isEmpty &&
      escalations.isEmpty &&
      smartTasks.isEmpty &&
      executionReminders.isEmpty &&
      priorityCustomers == 0;

  if (allQuiet) {
    return const BrokerDashboardIntelligenceLines(
      recentLine: 'Operasyonel özet: acil kuyruk sakin; detaylar aşağıda.',
    );
  }

  return BrokerDashboardIntelligenceLines(
    recentLine: recent,
    criticalLine: critical,
    nextLine: next,
    teamFocusLine: team,
  );
}

String? _lineCritical(
  int escTotal,
  int escCrit,
  int escHigh,
  int remCrit,
  int remHigh,
  int priorityCustomers,
) {
  if (escTotal == 0 &&
      remCrit == 0 &&
      remHigh == 0 &&
      escCrit == 0 &&
      escHigh == 0 &&
      priorityCustomers == 0) {
    return 'Kritik: bekleyen taşıma veya öncelikli sinyal yok.';
  }
  final parts = <String>[];
  if (escTotal > 0) {
    parts.add(
      '$escTotal yönetici taşıması${escCrit > 0 ? ' ($escCrit kritik)' : escHigh > 0 ? ' ($escHigh yüksek)' : ''}',
    );
  }
  if (remCrit > 0 || remHigh > 0) {
    parts.add(
      '${remCrit + remHigh} icra hatırlatıcısı${remCrit > 0 ? ' ($remCrit kritik)' : ''}',
    );
  }
  if (priorityCustomers > 0) {
    parts.add('$priorityCustomers öncelikli çağrı müşterisi');
  }
  if (parts.isEmpty) return 'Kritik kuyruk düşük; aşağıdaki kartları kontrol edin.';
  return 'Kritik odak: ${parts.join(' · ')}.';
}

String? _lineNext(
  List<ManagerEscalationItem> escalations,
  List<SmartTaskSuggestion> smartTasks,
  List<ExecutionReminderItem> executionReminders,
) {
  if (smartTasks.isNotEmpty) {
    return 'Sonraki: ${_truncate(smartTasks.first.taskSuggestionLabelTr, 72)}';
  }
  if (executionReminders.isNotEmpty) {
    return 'Sonraki: ${_truncate(executionReminders.first.reminderTitleTr, 72)}';
  }
  if (escalations.isNotEmpty) {
    return 'Sonraki: ${_truncate(escalations.first.escalationTitleTr, 72)}';
  }
  return null;
}

String? _lineTeamFocus(
  int priorityCustomers,
  int reminderCount,
  int taskSuggestionCount,
  int alertCount,
) {
  final parts = <String>[];
  if (priorityCustomers > 0) parts.add('$priorityCustomers öncelikli müşteri');
  if (reminderCount > 0) parts.add('$reminderCount hatırlatıcı');
  if (taskSuggestionCount > 0) parts.add('$taskSuggestionCount görev önerisi');
  if (alertCount > 0) parts.add('$alertCount uyarı satırı');
  if (parts.isEmpty) return null;
  return 'Takım odağı: ${parts.join(' · ')}.';
}

String _truncate(String s, int max) {
  final t = s.trim();
  if (t.length <= max) return t;
  var cut = t.substring(0, max);
  final sp = cut.lastIndexOf(' ');
  if (sp > 28) cut = cut.substring(0, sp);
  return '$cut…';
}
