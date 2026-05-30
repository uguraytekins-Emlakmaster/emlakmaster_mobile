import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/utils/war_room_intervention_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildWarRoomPriorityLanes', () {
    test('only includes lanes with real counts', () {
      const health = AdminOfficeHealthSummary(
        openTasks: 3,
        missedCalls: 2,
        followUpQueue: 5,
        setupPending: 1,
        officeAlerts: 2,
        escalations: 1,
      );
      final lanes = buildWarRoomPriorityLanes(health: health);
      expect(lanes.any((l) => l.kind == WarRoomLaneKind.overdueTasks), isTrue);
      expect(lanes.any((l) => l.kind == WarRoomLaneKind.missedCalls), isTrue);
      expect(lanes.every((l) => l.count > 0), isTrue);
    });

    test('empty health yields no lanes', () {
      final lanes = buildWarRoomPriorityLanes(
        health: AdminOfficeHealthSummary.empty,
      );
      expect(lanes, isEmpty);
    });
  });

  group('buildWarRoomInterventionRows', () {
    test('uses real escalation and alert metadata only', () {
      const escalation = ManagerEscalationItem(
        code: EscalationCode.hotNeglected,
        escalationTitleTr: 'Sıcak müşteri ihmal',
        escalationDescriptionTr: 'Detay',
        escalationPriority: EscalationPriority.critical,
        relatedCustomerId: 'c1',
        customerName: 'Ayşe Y.',
      );
      const alert = BrokerCustomerAlertItem(
        customerId: 'c2',
        customerName: 'Mehmet K.',
        code: BrokerAlertCode.urgentFollowUpMissed,
        alertTitleTr: 'Takip kaçırıldı',
        alertDescriptionTr: 'Detay',
        priorityLevel: BrokerAlertPriority.high,
      );
      final rows = buildWarRoomInterventionRows(
        escalations: [escalation],
        alerts: [alert],
        followUp: const [],
        syncRisk: const [],
        openTasks: 0,
      );
      expect(rows.length, 2);
      expect(rows.first.title, 'Sıcak müşteri ihmal');
      expect(rows.first.severityLabel, 'Kritik');
      expect(rows.any((r) => r.title == 'Takip kaçırıldı'), isTrue);
    });

    test('does not invent rows when sources empty', () {
      final rows = buildWarRoomInterventionRows(
        escalations: const [],
        alerts: const [],
        followUp: const [],
        syncRisk: const [],
        openTasks: 0,
      );
      expect(rows, isEmpty);
    });

    test('follow-up overdue uses segment label', () {
      final rows = buildWarRoomInterventionRows(
        escalations: const [],
        alerts: const [],
        followUp: [
          const ResurrectionQueueItem(
            customerId: 'c3',
            customerName: 'Ali V.',
            segment: ResurrectionSegment.silent14,
            daysSilent: 16,
          ),
        ],
        syncRisk: const [],
        openTasks: 0,
      );
      expect(rows.length, 1);
      expect(rows.first.severityLabel, '14 gün sessiz');
      expect(rows.first.followUpItem, isNotNull);
    });
  });

  group('honesty', () {
    test('crisis strip hides zero-value cells', () {
      expect(
        const AdminOfficeHealthSummary(missedCalls: 0, openTasks: 0).hasAny,
        isFalse,
      );
    });
  });
}
