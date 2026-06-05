import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/consultant_tasks_tokens.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/models/task_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/task_list_row_quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yüksek yoğunluklu görev satırı.
class TaskListPremiumTile extends ConsumerWidget {
  const TaskListPremiumTile({
    super.key,
    required this.taskId,
    required this.title,
    required this.done,
    required this.row,
    this.customerId,
    this.isDeleting = false,
    this.onTap,
    this.onComplete,
    this.onPostpone,
    this.onOpenCustomer,
    this.onEdit,
  });

  final String taskId;
  final String title;
  final bool done;
  final TaskListRowSnapshot row;
  final String? customerId;
  final bool isDeleting;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onPostpone;
  final VoidCallback? onOpenCustomer;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final cid = customerId?.trim();
    final customerAsync = cid != null && cid.isNotEmpty
        ? ref.watch(customerEntityByIdProvider(cid))
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ConsultantTasksTokens.rowPaddingH,
          ConsultantTasksTokens.rowPaddingV,
          ConsultantTasksTokens.rowPaddingH,
          ConsultantTasksTokens.rowPaddingV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: ConsultantTasksTokens.rowCheckSize,
                  height: ConsultantTasksTokens.rowCheckSize,
                  child: Checkbox(
                    value: done,
                    onChanged: isDeleting ? null : (_) => onComplete?.call(),
                    activeColor: premium.champagneGold,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: ext.border.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: done
                                    ? ext.textSecondary.withValues(alpha: 0.75)
                                    : ext.textPrimary,
                                fontWeight:
                                    done ? FontWeight.w500 : FontWeight.w800,
                                fontSize: ConsultantTasksTokens.rowTitleSize,
                                fontStyle:
                                    done ? FontStyle.italic : FontStyle.normal,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                letterSpacing: -0.2,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _StatusChip(status: row.dueStatus),
                        ],
                      ),
                      if (row.dueLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.dueLabel!,
                          style: TextStyle(
                            color: switch (row.dueStatus) {
                              TaskDueStatus.overdue => ext.danger,
                              TaskDueStatus.today => ext.warning,
                              TaskDueStatus.completed => ext.textTertiary,
                              _ => ext.textSecondary,
                            },
                            fontSize: ConsultantTasksTokens.rowMetaSize,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (row.hasRecurrence && row.recurrenceLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.recurrenceLabel!,
                          style: TextStyle(
                            color: ext.accent.withValues(alpha: 0.9),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (cid != null && cid.isNotEmpty) ...[
              const SizedBox(height: 4),
              _CustomerContextChip(
                customerAsync: customerAsync,
                customerId: cid,
                onTap: onOpenCustomer,
              ),
            ],
            if (onComplete != null ||
                onPostpone != null ||
                onOpenCustomer != null ||
                onEdit != null) ...[
              const SizedBox(height: 4),
              TaskListRowQuickActions(
                onComplete: isDeleting ? null : onComplete,
                onPostpone: isDeleting ? null : onPostpone,
                onOpenCustomer: onOpenCustomer,
                onEdit: onEdit,
                hasCustomer: cid != null && cid.isNotEmpty,
                isDone: done,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TaskDueStatus status;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final (label, color) = switch (status) {
      TaskDueStatus.completed => ('Bitti', ext.textTertiary),
      TaskDueStatus.overdue => ('Geciken', ext.danger),
      TaskDueStatus.today => ('Bugün', ext.warning),
      TaskDueStatus.upcoming => ('Yaklaşan', ext.info),
      TaskDueStatus.noDue => ('Açık', ext.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: ConsultantTasksTokens.statusChipFontSize,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _CustomerContextChip extends StatelessWidget {
  const _CustomerContextChip({
    required this.customerAsync,
    required this.customerId,
    this.onTap,
  });

  final AsyncValue<CustomerEntity?>? customerAsync;
  final String customerId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final label = customerAsync?.maybeWhen(
          data: (entity) => entity?.fullName?.trim(),
          orElse: () => null,
        ) ??
        'Müşteri';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ext.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          border: Border.all(color: ext.accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_rounded,
              size: 12,
              color: ext.accent.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label.isEmpty ? 'Müşteri' : label,
                style: TextStyle(
                  color: ext.accent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
