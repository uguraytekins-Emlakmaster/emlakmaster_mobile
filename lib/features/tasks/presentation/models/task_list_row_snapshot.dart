import 'package:emlakmaster_mobile/features/tasks/domain/task_recurrence.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';

/// Görev satırı durum göstergesi — Firestore öncelik alanı yok; vade türetilir.
enum TaskDueStatus {
  completed,
  overdue,
  today,
  upcoming,
  noDue,
}

class TaskListRowSnapshot {
  const TaskListRowSnapshot({
    required this.dueStatus,
    required this.dueLabel,
    required this.hasRecurrence,
    this.recurrenceLabel,
  });

  final TaskDueStatus dueStatus;
  final String? dueLabel;
  final bool hasRecurrence;
  final String? recurrenceLabel;

  factory TaskListRowSnapshot.fromTaskData(
    Map<String, dynamic> data, {
    required DateTime today,
  }) {
    final done = taskDocIsDone(data);
    final dueAt = taskDocDueAt(data);
    final todayFloor = taskListDayFloor(today);
    final recurrence = data['recurrence'] as String?;
    final hasRecurrence = recurrence is String && recurrence.isNotEmpty;

    if (done) {
      return TaskListRowSnapshot(
        dueStatus: TaskDueStatus.completed,
        dueLabel: dueAt != null ? _formatDueLabel(dueAt, todayFloor, false) : 'Tamamlandı',
        hasRecurrence: hasRecurrence,
        recurrenceLabel: taskRecurrenceLabel(recurrence),
      );
    }

    if (dueAt == null) {
      return TaskListRowSnapshot(
        dueStatus: TaskDueStatus.noDue,
        dueLabel: 'Vade yok',
        hasRecurrence: hasRecurrence,
        recurrenceLabel: taskRecurrenceLabel(recurrence),
      );
    }

    final dueDay = taskListDayFloor(dueAt);
    final isOverdue = dueDay.isBefore(todayFloor);
    final isToday = dueDay == todayFloor;

    return TaskListRowSnapshot(
      dueStatus: isOverdue
          ? TaskDueStatus.overdue
          : isToday
              ? TaskDueStatus.today
              : TaskDueStatus.upcoming,
      dueLabel: _formatDueLabel(dueAt, todayFloor, isOverdue),
      hasRecurrence: hasRecurrence,
      recurrenceLabel: taskRecurrenceLabel(recurrence),
    );
  }
}

String _formatDueLabel(DateTime due, DateTime todayFloor, bool isOverdue) {
  final dueDay = taskListDayFloor(due);
  final diff = dueDay.difference(todayFloor).inDays;
  if (diff == 0) return 'Bugün';
  if (diff == 1) return 'Yarın';
  if (diff == -1) return 'Dün (geçti)';
  if (diff < -1) return '${-diff} gün gecikti';
  if (diff <= 7) return '$diff gün içinde';
  return '${due.day}.${due.month}.${due.year}';
}
