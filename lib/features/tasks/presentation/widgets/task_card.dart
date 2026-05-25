import 'package:emlakmaster_mobile/features/tasks/presentation/models/task_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/task_list_operating_card.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/task_list_premium_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Görev kartı — [TaskListPremiumTile] + operating card kabuğu.
class TaskCard extends ConsumerWidget {
  const TaskCard({
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
    return Semantics(
      label: '$title görevi',
      button: true,
      child: TaskListOperatingCard(
        emphasizeOverdue: row.dueStatus == TaskDueStatus.overdue && !done,
        child: TaskListPremiumTile(
          taskId: taskId,
          title: title,
          done: done,
          row: row,
          customerId: customerId,
          isDeleting: isDeleting,
          onTap: onTap,
          onComplete: onComplete,
          onPostpone: onPostpone,
          onOpenCustomer: onOpenCustomer,
          onEdit: onEdit,
        ),
      ),
    );
  }
}
