import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/execution_reminder.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/smart_task_suggestion.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_alerts_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_smart_task_suggestions_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/execution_reminders_providers.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/manager_escalations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const int _kLeanFocusMaxRows = 4;

/// Lean V1: operasyonel özetten sonra ritim — tek bakışta yapılacaklar (hafif).
class LeanAdminTodayFocusCard extends ConsumerWidget {
  const LeanAdminTodayFocusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    if (!role.isManagerTier) return const SizedBox.shrink();

    final remindersAsync = ref.watch(brokerExecutionRemindersProvider);
    final tasksAsync = ref.watch(brokerSmartTaskSuggestionsProvider);
    final escAsync = ref.watch(managerEscalationsProvider);

    if (remindersAsync.isLoading || tasksAsync.isLoading || escAsync.isLoading) {
      return _LeanCardShell(
        title: 'Bugünün odağı',
        subtitle: 'Acil takip, taşıma ve görev öncelikleri',
        icon: Icons.center_focus_strong_outlined,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppThemeExtension.of(context).accent,
              ),
            ),
          ),
        ),
      );
    }

    final reminders = remindersAsync.value ?? [];
    final tasks = tasksAsync.value ?? [];
    final esc = escAsync.value ?? [];

    final rows = _buildFocusRows(
      escalations: esc,
      reminders: reminders,
      tasks: tasks,
    );

    return _LeanCardShell(
      title: 'Bugünün odağı',
      subtitle: 'Acil takip, taşıma ve görev öncelikleri',
      icon: Icons.center_focus_strong_outlined,
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: DesignTokens.space1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 18, color: AppThemeExtension.of(context).accent.withValues(alpha: 0.85)),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: Text(
                      'Öncelik kuyruğu sakin; yeni sinyaller geldiğinde burada listelenir.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppThemeExtension.of(context).textSecondary,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < rows.length && i < _kLeanFocusMaxRows; i++) ...[
                  if (i > 0) const SizedBox(height: DesignTokens.space2),
                  _FocusRowTile(row: rows[i]),
                ],
              ],
            ),
    );
  }
}

class _FocusRowData {
  const _FocusRowData({
    required this.title,
    required this.subtitle,
    required this.customerId,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String customerId;
  final IconData icon;
}

List<_FocusRowData> _buildFocusRows({
  required List<ManagerEscalationItem> escalations,
  required List<ExecutionReminderItem> reminders,
  required List<SmartTaskSuggestion> tasks,
}) {
  final escSorted = [...escalations]..sort((a, b) => _escalationRank(a).compareTo(_escalationRank(b)));
  final remSorted = [...reminders]..sort((a, b) => _reminderRank(a).compareTo(_reminderRank(b)));
  final taskSorted = [...tasks]..sort((a, b) => _taskRank(a).compareTo(_taskRank(b)));

  final out = <_FocusRowData>[];

  for (final e in escSorted.take(1)) {
    out.add(
      _FocusRowData(
        title: _truncate(e.escalationTitleTr, 52),
        subtitle: _truncate(e.customerName ?? 'Müşteri', 36),
        customerId: e.relatedCustomerId,
        icon: Icons.move_up_rounded,
      ),
    );
  }
  for (final r in remSorted.take(2)) {
    out.add(
      _FocusRowData(
        title: _truncate(r.reminderTitleTr, 52),
        subtitle: _truncate(r.customerName ?? 'Müşteri', 36),
        customerId: r.relatedCustomerId,
        icon: Icons.alarm_rounded,
      ),
    );
  }
  for (final t in taskSorted.take(2)) {
    out.add(
      _FocusRowData(
        title: _truncate(t.taskSuggestionLabelTr, 52),
        subtitle: _truncate(t.customerName ?? 'Müşteri', 36),
        customerId: t.relatedCustomerId,
        icon: Icons.task_alt_rounded,
      ),
    );
  }

  if (out.length <= _kLeanFocusMaxRows) return out;
  return out.take(_kLeanFocusMaxRows).toList();
}

int _escalationRank(ManagerEscalationItem e) {
  switch (e.escalationPriority) {
    case EscalationPriority.critical:
      return 0;
    case EscalationPriority.high:
      return 1;
    case EscalationPriority.medium:
      return 2;
  }
}

int _reminderRank(ExecutionReminderItem r) {
  switch (r.reminderPriority) {
    case ExecutionReminderPriority.critical:
      return 0;
    case ExecutionReminderPriority.high:
      return 1;
    case ExecutionReminderPriority.medium:
      return 2;
  }
}

int _taskRank(SmartTaskSuggestion t) {
  switch (t.urgency) {
    case TaskSuggestionUrgency.high:
      return 0;
    case TaskSuggestionUrgency.medium:
      return 1;
    case TaskSuggestionUrgency.low:
      return 2;
  }
}

String _truncate(String s, int max) {
  final t = s.trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max > 3 ? max - 1 : max)}…';
}

/// Tek satırlık ofis sinyali — Analytics’ten hafif; uyarı motorundan.
class LeanAdminOfficePulseCard extends ConsumerWidget {
  const LeanAdminOfficePulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    if (!role.isManagerTier) return const SizedBox.shrink();

    final async = ref.watch(brokerDashboardAlertsProvider);
    return async.when(
      data: (alerts) {
        final sorted = [...alerts]..sort((a, b) => _alertRank(a).compareTo(_alertRank(b)));
        final top = sorted.isEmpty ? null : sorted.first;

        final ext = AppThemeExtension.of(context);
        final body = top == null
            ? Text(
                'Öncelikli ofis uyarısı yok; müşteri sinyalleri izleniyor.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ext.textSecondary,
                      height: 1.38,
                    ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _truncate(top.alertTitleTr, 88),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                  ),
                  if ((top.aiInsightLineTr ?? top.alertDescriptionTr).trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _truncate((top.aiInsightLineTr ?? top.alertDescriptionTr).trim(), 120),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ext.textTertiary,
                            height: 1.35,
                          ),
                    ),
                  ],
                ],
              );

        return _LeanCardShell(
          title: 'Ofis nabzı',
          subtitle: 'Güncel risk / fırsat sinyali',
          icon: Icons.monitor_heart_outlined,
          dense: true,
          trailing: top != null
              ? TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/customer/${top.customerId}');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: ext.accent,
                  ),
                  child: const Text('Detay'),
                )
              : null,
          child: body,
        );
      },
      loading: () => _LeanCardShell(
        title: 'Ofis nabzı',
        subtitle: 'Güncel risk / fırsat sinyali',
        icon: Icons.monitor_heart_outlined,
        dense: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space2),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppThemeExtension.of(context).accent,
              ),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

int _alertRank(BrokerCustomerAlertItem a) {
  switch (a.priorityLevel) {
    case BrokerAlertPriority.high:
      return 0;
    case BrokerAlertPriority.medium:
      return 1;
    case BrokerAlertPriority.low:
      return 2;
  }
}

class _FocusRowTile extends StatelessWidget {
  const _FocusRowTile({required this.row});

  final _FocusRowData row;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surface.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/customer/${row.customerId}');
        },
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3, vertical: 10),
          child: Row(
            children: [
              Icon(row.icon, size: 18, color: ext.accent.withValues(alpha: 0.95)),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ext.textTertiary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ext.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeanCardShell extends StatelessWidget {
  const _LeanCardShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.dense = false,
    this.trailing,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool dense;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.space4),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(dense ? DesignTokens.space3 : DesignTokens.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
            color: ext.surfaceElevated,
            border: Border.all(color: ext.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: dense ? 19 : 20, color: ext.accent),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.15,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ext.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              SizedBox(height: dense ? DesignTokens.space2 : DesignTokens.space3),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
