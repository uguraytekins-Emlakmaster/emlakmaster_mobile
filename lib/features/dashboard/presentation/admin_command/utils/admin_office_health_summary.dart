import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_ui_state.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_lifecycle.dart';

/// Ofis sağlık şeridi — yalnızca gerçek sayaçlar.
class AdminOfficeHealthSummary {
  const AdminOfficeHealthSummary({
    this.activeAdvisors = 0,
    this.openTasks = 0,
    this.liveCalls = 0,
    this.missedCalls = 0,
    this.officeAlerts = 0,
    this.highAlerts = 0,
    this.escalations = 0,
    this.criticalEscalations = 0,
    this.followUpQueue = 0,
    this.setupPending = 0,
    this.syncRisk = 0,
  });

  final int activeAdvisors;
  final int openTasks;
  final int liveCalls;
  final int missedCalls;
  final int officeAlerts;
  final int highAlerts;
  final int escalations;
  final int criticalEscalations;
  final int followUpQueue;
  final int setupPending;
  final int syncRisk;

  static const empty = AdminOfficeHealthSummary();

  bool get hasAny =>
      activeAdvisors > 0 ||
      openTasks > 0 ||
      liveCalls > 0 ||
      missedCalls > 0 ||
      officeAlerts > 0 ||
      escalations > 0 ||
      followUpQueue > 0 ||
      setupPending > 0 ||
      syncRisk > 0;
}

enum AdminUrgentKind {
  escalation,
  alert,
  sync,
  integration,
  missedCalls,
  followUp,
}

/// Acil komuta bloğu — gerçek veriden türetilir.
class AdminCommandUrgentItem {
  const AdminCommandUrgentItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.iconName,
    this.count = 0,
  });

  final String id;
  final AdminUrgentKind kind;
  final String title;
  final String subtitle;
  final String iconName;
  final int count;
}

class AdminCommandSnapshot {
  const AdminCommandSnapshot({
    required this.health,
    required this.urgentItems,
  });

  final AdminOfficeHealthSummary health;
  final List<AdminCommandUrgentItem> urgentItems;

  static const empty = AdminCommandSnapshot(
    health: AdminOfficeHealthSummary.empty,
    urgentItems: [],
  );
}

int countIntegrationSetupPending(Iterable<IntegrationPlatform> platforms) {
  var attention = 0;
  for (final p in platforms) {
    final needsAttention = p.setupLifecycle != null
        ? p.setupLifecycle!.countsAsAttentionForDashboard
        : (p.truthKind == PlatformConnectionTruthKind.setupIncomplete ||
            p.connectionState == PlatformConnectionUiState.needsAttention);
    if (needsAttention) attention++;
  }
  return attention;
}

AdminOfficeHealthSummary computeAdminOfficeHealthSummary({
  required int activeAdvisors,
  required int openTasks,
  required int liveCalls,
  required int missedCalls,
  required List<BrokerCustomerAlertItem> alerts,
  required List<ManagerEscalationItem> escalations,
  required int followUpQueue,
  required int setupPending,
  required int syncRisk,
}) {
  final highAlerts =
      alerts.where((a) => a.priorityLevel == BrokerAlertPriority.high).length;
  final critEsc = escalations
      .where((e) => e.escalationPriority == EscalationPriority.critical)
      .length;

  return AdminOfficeHealthSummary(
    activeAdvisors: activeAdvisors,
    openTasks: openTasks,
    liveCalls: liveCalls,
    missedCalls: missedCalls,
    officeAlerts: alerts.length,
    highAlerts: highAlerts,
    escalations: escalations.length,
    criticalEscalations: critEsc,
    followUpQueue: followUpQueue,
    setupPending: setupPending,
    syncRisk: syncRisk,
  );
}

List<AdminCommandUrgentItem> buildAdminCommandUrgentItems({
  required AdminOfficeHealthSummary health,
  required List<BrokerCustomerAlertItem> alerts,
  required List<ManagerEscalationItem> escalations,
}) {
  final items = <AdminCommandUrgentItem>[];

  if (health.criticalEscalations > 0) {
    final top = escalations.firstWhere(
      (e) => e.escalationPriority == EscalationPriority.critical,
      orElse: () => escalations.first,
    );
    items.add(
      AdminCommandUrgentItem(
        id: 'esc_crit',
        kind: AdminUrgentKind.escalation,
        title: 'Kritik taşıma',
        subtitle: top.escalationTitleTr,
        iconName: 'escalation',
        count: health.criticalEscalations,
      ),
    );
  } else if (health.escalations > 0) {
    items.add(
      AdminCommandUrgentItem(
        id: 'esc',
        kind: AdminUrgentKind.escalation,
        title: 'Yönetici taşıması',
        subtitle: escalations.first.escalationTitleTr,
        iconName: 'escalation',
        count: health.escalations,
      ),
    );
  }

  if (health.highAlerts > 0) {
    final top = alerts.firstWhere(
      (a) => a.priorityLevel == BrokerAlertPriority.high,
      orElse: () => alerts.first,
    );
    items.add(
      AdminCommandUrgentItem(
        id: 'alert_high',
        kind: AdminUrgentKind.alert,
        title: 'Yüksek ofis uyarısı',
        subtitle: top.alertTitleTr,
        iconName: 'alert',
        count: health.highAlerts,
      ),
    );
  } else if (health.officeAlerts > 0) {
    items.add(
      AdminCommandUrgentItem(
        id: 'alert',
        kind: AdminUrgentKind.alert,
        title: 'Ofis uyarısı',
        subtitle: alerts.first.alertTitleTr,
        iconName: 'alert',
        count: health.officeAlerts,
      ),
    );
  }

  if (health.syncRisk > 0) {
    items.add(
      AdminCommandUrgentItem(
        id: 'sync',
        kind: AdminUrgentKind.sync,
        title: 'Senkron riski',
        subtitle: '${health.syncRisk} müşteride veri / senkron riski',
        iconName: 'sync',
        count: health.syncRisk,
      ),
    );
  }

  if (health.setupPending > 0) {
    items.add(
      AdminCommandUrgentItem(
        id: 'integration',
        kind: AdminUrgentKind.integration,
        title: 'Kanal kurulumu',
        subtitle: '${health.setupPending} kanalda kurulum veya doğrulama bekliyor',
        iconName: 'integration',
        count: health.setupPending,
      ),
    );
  }

  if (health.missedCalls > 0) {
    items.add(
      AdminCommandUrgentItem(
        id: 'missed',
        kind: AdminUrgentKind.missedCalls,
        title: 'Kaçırılan çağrılar',
        subtitle: 'Ofis genelinde ${health.missedCalls} kaçırılan çağrı',
        iconName: 'missed',
        count: health.missedCalls,
      ),
    );
  }

  if (health.followUpQueue > 0 && items.length < 4) {
    items.add(
      AdminCommandUrgentItem(
        id: 'follow_up',
        kind: AdminUrgentKind.followUp,
        title: 'Takip baskısı',
        subtitle: '${health.followUpQueue} sessiz / geri kazanım adayı',
        iconName: 'follow_up',
        count: health.followUpQueue,
      ),
    );
  }

  return items.take(4).toList(growable: false);
}
