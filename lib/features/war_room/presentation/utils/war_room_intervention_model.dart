import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_ui_formatters.dart';

enum WarRoomInterventionAction {
  commandCenter,
  connectedAccounts,
  customerDetail,
  reportsTab,
  followUpSheet,
}

enum WarRoomLaneKind {
  overdueTasks,
  followUpPressure,
  missedCalls,
  integration,
  alertsEscalation,
  teamSignal,
}

class WarRoomPriorityLane {
  const WarRoomPriorityLane({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.action,
  });

  final String id;
  final WarRoomLaneKind kind;
  final String title;
  final String subtitle;
  final int count;
  final WarRoomInterventionAction action;
}

class WarRoomInterventionRow {
  const WarRoomInterventionRow({
    required this.id,
    required this.title,
    required this.source,
    required this.detail,
    required this.severityLabel,
    required this.action,
    this.targetId,
    this.ownerLabel,
    this.followUpItem,
  });

  final String id;
  final String title;
  final String source;
  final String detail;
  final String severityLabel;
  final WarRoomInterventionAction action;
  final String? targetId;
  final String? ownerLabel;
  final ResurrectionQueueItem? followUpItem;
}

class WarRoomInterventionSnapshot {
  const WarRoomInterventionSnapshot({
    required this.health,
    required this.lanes,
    required this.interventions,
  });

  final AdminOfficeHealthSummary health;
  final List<WarRoomPriorityLane> lanes;
  final List<WarRoomInterventionRow> interventions;

  static const empty = WarRoomInterventionSnapshot(
    health: AdminOfficeHealthSummary.empty,
    lanes: [],
    interventions: [],
  );

  bool get hasPressure =>
      health.hasAny || lanes.isNotEmpty || interventions.isNotEmpty;
}

String _escalationSeverity(EscalationPriority p) => switch (p) {
      EscalationPriority.critical => 'Kritik',
      EscalationPriority.high => 'Yüksek',
      EscalationPriority.medium => 'Orta',
    };

String _alertSeverity(BrokerAlertPriority p) => switch (p) {
      BrokerAlertPriority.high => 'Yüksek',
      BrokerAlertPriority.medium => 'Orta',
      BrokerAlertPriority.low => 'Düşük',
    };

List<WarRoomPriorityLane> buildWarRoomPriorityLanes({
  required AdminOfficeHealthSummary health,
}) {
  final lanes = <WarRoomPriorityLane>[];

  if (health.openTasks > 0) {
    lanes.add(
      WarRoomPriorityLane(
        id: 'lane_tasks',
        kind: WarRoomLaneKind.overdueTasks,
        title: 'Geciken işler',
        subtitle: '${health.openTasks} açık görev',
        count: health.openTasks,
        action: WarRoomInterventionAction.reportsTab,
      ),
    );
  }

  if (health.followUpQueue > 0) {
    lanes.add(
      WarRoomPriorityLane(
        id: 'lane_follow_up',
        kind: WarRoomLaneKind.followUpPressure,
        title: 'Takip baskısı',
        subtitle: '${health.followUpQueue} sessiz müşteri',
        count: health.followUpQueue,
        action: WarRoomInterventionAction.followUpSheet,
      ),
    );
  }

  if (health.missedCalls > 0) {
    lanes.add(
      WarRoomPriorityLane(
        id: 'lane_missed',
        kind: WarRoomLaneKind.missedCalls,
        title: 'Kaçırılan çağrılar',
        subtitle: 'Ofis geneli ${health.missedCalls}',
        count: health.missedCalls,
        action: WarRoomInterventionAction.commandCenter,
      ),
    );
  }

  if (health.setupPending > 0 || health.syncRisk > 0) {
    final total = health.setupPending + health.syncRisk;
    lanes.add(
      WarRoomPriorityLane(
        id: 'lane_integration',
        kind: WarRoomLaneKind.integration,
        title: 'Entegrasyon / sync',
        subtitle: health.setupPending > 0 && health.syncRisk > 0
            ? '${health.setupPending} kurulum · ${health.syncRisk} sync'
            : health.setupPending > 0
                ? '${health.setupPending} kanal kurulum bekliyor'
                : '${health.syncRisk} senkron riski',
        count: total,
        action: WarRoomInterventionAction.connectedAccounts,
      ),
    );
  }

  if (health.escalations > 0 || health.officeAlerts > 0) {
    final total = health.escalations + health.officeAlerts;
    lanes.add(
      WarRoomPriorityLane(
        id: 'lane_alerts',
        kind: WarRoomLaneKind.alertsEscalation,
        title: 'Uyarı / taşıma',
        subtitle: health.criticalEscalations > 0
            ? '${health.criticalEscalations} kritik taşıma'
            : '${health.escalations} taşıma · ${health.officeAlerts} uyarı',
        count: total,
        action: WarRoomInterventionAction.commandCenter,
      ),
    );
  }

  if (health.activeAdvisors > 0 &&
      health.missedCalls > 0 &&
      health.missedCalls >= health.activeAdvisors) {
    lanes.add(
      WarRoomPriorityLane(
        id: 'lane_team',
        kind: WarRoomLaneKind.teamSignal,
        title: 'Ekip baskısı',
        subtitle: 'Kaçırılan çağrı danışman sayısını aşıyor',
        count: health.missedCalls,
        action: WarRoomInterventionAction.reportsTab,
      ),
    );
  }

  return lanes;
}

List<WarRoomInterventionRow> buildWarRoomInterventionRows({
  required List<ManagerEscalationItem> escalations,
  required List<BrokerCustomerAlertItem> alerts,
  required List<ResurrectionQueueItem> followUp,
  required List<CustomerRevenueRow> syncRisk,
  required int openTasks,
}) {
  final rows = <WarRoomInterventionRow>[];

  final sortedEsc = [...escalations]
    ..sort((a, b) => a._sortKey.compareTo(b._sortKey));
  for (final e in sortedEsc.take(4)) {
    rows.add(
      WarRoomInterventionRow(
        id: 'esc_${e.dedupeKey}',
        title: e.escalationTitleTr,
        source: 'Yönetici taşıması',
        detail: e.customerName ?? e.relatedCustomerId,
        severityLabel: _escalationSeverity(e.escalationPriority),
        action: WarRoomInterventionAction.customerDetail,
        targetId: e.relatedCustomerId,
      ),
    );
  }

  final sortedAlerts = [...alerts]
    ..sort((a, b) => a.priorityLevel.index.compareTo(b.priorityLevel.index));
  for (final a in sortedAlerts.take(4)) {
    rows.add(
      WarRoomInterventionRow(
        id: 'alert_${a.customerId}_${a.code.name}',
        title: a.alertTitleTr,
        source: 'Ofis uyarısı',
        detail: a.customerName ?? a.customerId,
        severityLabel: _alertSeverity(a.priorityLevel),
        action: WarRoomInterventionAction.customerDetail,
        targetId: a.customerId,
      ),
    );
  }

  final overdueFollowUp = followUp
      .where(
        (f) => (f.daysSilent ?? 0) >= ResurrectionSegment.silent14.daysThreshold,
      )
      .toList()
    ..sort((a, b) => (b.daysSilent ?? 0).compareTo(a.daysSilent ?? 0));

  for (final f in overdueFollowUp.take(4)) {
    rows.add(
      WarRoomInterventionRow(
        id: 'follow_${f.customerId}',
        title: 'Takip gecikmesi · ${f.daysSilent ?? 0} gün',
        source: 'Geri kazanım',
        detail: f.customerName ?? f.customerId,
        severityLabel: f.segment?.label ?? 'Takip',
        action: WarRoomInterventionAction.followUpSheet,
        targetId: f.customerId,
        followUpItem: f,
      ),
    );
  }

  for (final s in syncRisk.take(3)) {
    rows.add(
      WarRoomInterventionRow(
        id: 'sync_${s.customerId}',
        title: s.displayName,
        source: 'Senkron riski',
        detail: revenueNextActionVerbTr(s.nextAction),
        severityLabel: 'Sync',
        action: WarRoomInterventionAction.connectedAccounts,
        targetId: s.customerId,
      ),
    );
  }

  if (openTasks > 0 && rows.length < 8) {
    rows.add(
      WarRoomInterventionRow(
        id: 'tasks_open',
        title: '$openTasks açık görev',
        source: 'Görev kuyruğu',
        detail: 'Tamamlanmamış ofis görevleri',
        severityLabel: 'İş',
        action: WarRoomInterventionAction.reportsTab,
      ),
    );
  }

  return rows.take(10).toList(growable: false);
}

extension on ManagerEscalationItem {
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
