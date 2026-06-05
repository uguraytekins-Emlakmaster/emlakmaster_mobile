import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:flutter_test/flutter_test.dart';

BrokerCustomerAlertItem _alert(BrokerAlertPriority p) {
  return BrokerCustomerAlertItem(
    customerId: 'c1',
    customerName: 'Test Müşteri',
    code: BrokerAlertCode.hotCustomerIdle,
    alertTitleTr: 'Test uyarısı',
    alertDescriptionTr: 'Detay',
    priorityLevel: p,
  );
}

ManagerEscalationItem _esc(EscalationPriority p) {
  return ManagerEscalationItem(
    code: EscalationCode.hotNeglected,
    escalationTitleTr: 'Taşıma başlığı',
    escalationDescriptionTr: 'Detay',
    escalationPriority: p,
    relatedCustomerId: 'c2',
    customerName: 'Müşteri',
  );
}

void main() {
  test('computeAdminOfficeHealthSummary uses real counts only', () {
    final summary = computeAdminOfficeHealthSummary(
      activeAdvisors: 4,
      openTasks: 12,
      liveCalls: 2,
      missedCalls: 3,
      alerts: [
        _alert(BrokerAlertPriority.high),
        _alert(BrokerAlertPriority.medium),
      ],
      escalations: [_esc(EscalationPriority.critical)],
      followUpQueue: 7,
      setupPending: 2,
      syncRisk: 1,
    );

    expect(summary.activeAdvisors, 4);
    expect(summary.openTasks, 12);
    expect(summary.officeAlerts, 2);
    expect(summary.highAlerts, 1);
    expect(summary.criticalEscalations, 1);
    expect(summary.followUpQueue, 7);
    expect(summary.setupPending, 2);
    expect(summary.syncRisk, 1);
    expect(summary.hasAny, isTrue);
  });

  test('buildAdminCommandUrgentItems caps at four and prioritizes critical', () {
    final alerts = List.generate(3, (_) => _alert(BrokerAlertPriority.high));
    final escalations = [_esc(EscalationPriority.critical)];
    final health = computeAdminOfficeHealthSummary(
      activeAdvisors: 1,
      openTasks: 0,
      liveCalls: 0,
      missedCalls: 5,
      alerts: alerts,
      escalations: escalations,
      followUpQueue: 9,
      setupPending: 1,
      syncRisk: 2,
    );

    final urgent = buildAdminCommandUrgentItems(
      health: health,
      alerts: alerts,
      escalations: escalations,
    );

    expect(urgent.length, lessThanOrEqualTo(4));
    expect(urgent.first.kind, AdminUrgentKind.escalation);
    expect(urgent.any((e) => e.kind == AdminUrgentKind.sync), isTrue);
  });

  test('empty health summary has no urgent items without signals', () {
    const health = AdminOfficeHealthSummary.empty;
    final urgent = buildAdminCommandUrgentItems(
      health: health,
      alerts: const [],
      escalations: const [],
    );
    expect(urgent, isEmpty);
  });
}
