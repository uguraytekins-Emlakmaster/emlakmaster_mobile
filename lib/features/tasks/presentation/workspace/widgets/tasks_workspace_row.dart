import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/consultant_tasks_tokens.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/widgets/tasks_workspace_chrome.dart';
import 'package:flutter/material.dart';

enum TaskRowMenu {
  open,
  complete,
  customer,
  call,
  message,
  postpone,
  followUp,
  detail,
}

class TasksWorkspaceRow extends StatelessWidget {
  const TasksWorkspaceRow({
    super.key,
    required this.row,
    required this.onTap,
    required this.onComplete,
    required this.onMenu,
  });

  final TaskRowView row;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final void Function(TaskRowMenu) onMenu;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final tone = taskToneColor(ext, row.tone);
    final compact = MediaQuery.sizeOf(context).width < 360;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              ConsultantTasksTokens.horizontal,
              0,
              ConsultantTasksTokens.horizontal,
              ConsultantTasksTokens.chromeGap + 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ConsultantTasksTokens.rowPaddingH,
              vertical: ConsultantTasksTokens.rowPaddingV,
            ),
            decoration: BoxDecoration(
              color: ext.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: row.isOverdue
                    ? ext.danger.withValues(alpha: 0.35)
                    : ext.border.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: ConsultantTasksTokens.rowCheckSize,
                  height: ConsultantTasksTokens.rowCheckSize,
                  child: Checkbox(
                    value: row.done,
                    onChanged: (_) => onComplete(),
                    activeColor: ext.accent,
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
                      if (compact) ...[
                        Text(
                          row.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: row.done
                                ? ext.textSecondary.withValues(alpha: 0.75)
                                : ext.textPrimary,
                            fontSize: ConsultantTasksTokens.rowTitleSize,
                            fontWeight:
                                row.done ? FontWeight.w500 : FontWeight.w800,
                            decoration: row.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _StatusChip(label: row.statusLabel, color: tone),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: row.done
                                      ? ext.textSecondary
                                          .withValues(alpha: 0.75)
                                      : ext.textPrimary,
                                  fontSize: ConsultantTasksTokens.rowTitleSize,
                                  fontWeight: row.done
                                      ? FontWeight.w500
                                      : FontWeight.w800,
                                  decoration: row.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: _StatusChip(
                                label: row.statusLabel,
                                color: tone,
                              ),
                            ),
                          ],
                        ),
                      if (row.customerName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textSecondary.withValues(alpha: 0.9),
                            fontSize: ConsultantTasksTokens.rowMetaSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (row.nextActionLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.nextActionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (row.isPartial && row.partialNote.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.partialNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<TaskRowMenu>(
                  tooltip: l10n.t('row_actions'),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: ConsultantTasksTokens.actionIconSize + 2,
                    color: ext.textTertiary,
                  ),
                  onSelected: onMenu,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: TaskRowMenu.open,
                      child: Text(l10n.t('row_open')),
                    ),
                    if (!row.done)
                      PopupMenuItem(
                        value: TaskRowMenu.complete,
                        child: Text(l10n.t('row_complete')),
                      ),
                    if (row.customerId != null && row.customerId!.isNotEmpty)
                      PopupMenuItem(
                        value: TaskRowMenu.customer,
                        child: Text(l10n.t('row_go_customer')),
                      ),
                    if (!row.done)
                      PopupMenuItem(
                        value: TaskRowMenu.postpone,
                        child: Text(l10n.t('row_postpone')),
                      ),
                    PopupMenuItem(
                      value: TaskRowMenu.followUp,
                      child: Text(l10n.t('row_go_followup')),
                    ),
                    PopupMenuItem(
                      value: TaskRowMenu.detail,
                      child: Text(l10n.t('row_detail')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: ConsultantTasksTokens.statusChipFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
