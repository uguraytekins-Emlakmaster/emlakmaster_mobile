import 'package:emlakmaster_mobile/features/tasks/domain/task_recurrence.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/models/task_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';

TasksWorkspaceSnapshot computeTasksWorkspaceSnapshot(
  List<TaskWorkspaceInput> inputs, {
  required DateTime now,
}) {
  final todayFloor = taskListDayFloor(now);
  final rows = <TaskRowView>[];

  for (final t in inputs) {
    final title = t.title.trim().isNotEmpty ? t.title.trim() : 'İsimsiz görev';
    final rowSnap = TaskListRowSnapshot.fromTaskData(
      t.rawData,
      today: now,
    );

    final dueDay = t.dueAt != null ? taskListDayFloor(t.dueAt!) : null;
    final isOverdue = !t.done &&
        dueDay != null &&
        dueDay.isBefore(todayFloor);
    final isToday = !t.done && dueDay != null && dueDay == todayFloor;
    final isPartial =
        title == 'İsimsiz görev' || (!t.done && t.dueAt == null);
    final isMatched =
        t.customerId != null && t.customerId!.trim().isNotEmpty;
    final isPriority = isOverdue || isToday;
    final quickCloseable = isToday && !t.done;

    final partialNote = _partialNote(
      titleMissing: title == 'İsimsiz görev',
      dueMissing: !t.done && t.dueAt == null,
    );

    final statusLabel = rowSnap.dueLabel ?? (t.done ? 'Tamamlandı' : 'Açık');
    final contextLine = t.recurrence != null && t.recurrence!.isNotEmpty
        ? 'Tekrar: ${taskRecurrenceLabel(t.recurrence) ?? t.recurrence}'
        : (isMatched && (t.customerName ?? '').isNotEmpty
            ? t.customerName!
            : '');

    final nextAction = _nextAction(
      done: t.done,
      isOverdue: isOverdue,
      isToday: isToday,
      isMatched: isMatched,
    );

    rows.add(
      TaskRowView(
        id: t.id,
        title: title,
        done: t.done,
        dueLabel: statusLabel,
        statusLabel: statusLabel,
        contextLine: contextLine,
        nextActionLabel: nextAction,
        tone: _toneFor(
          done: t.done,
          isOverdue: isOverdue,
          isToday: isToday,
          isPartial: isPartial,
          isMatched: isMatched,
        ),
        isOverdue: isOverdue,
        isToday: isToday,
        isActive: !t.done,
        isCompleted: t.done,
        isPartial: isPartial,
        isMatched: isMatched,
        isPriority: isPriority,
        quickCloseable: quickCloseable,
        partialNote: partialNote,
        customerId: t.customerId,
        customerName: t.customerName ?? '',
        callablePhone: t.callablePhone,
        phone: t.phone,
        hasRecurrence: t.recurrence != null && t.recurrence!.isNotEmpty,
        recurrenceLabel: taskRecurrenceLabel(t.recurrence),
        sortRank: _sortRank(
          done: t.done,
          isOverdue: isOverdue,
          isToday: isToday,
          isPartial: isPartial,
        ),
        searchText:
            '$title ${t.customerName ?? ''} $statusLabel ${t.recurrence ?? ''}'
                .toLowerCase(),
        rawData: t.rawData,
      ),
    );
  }

  rows.sort((a, b) {
    final r = a.sortRank.compareTo(b.sortRank);
    if (r != 0) return r;
    return a.title.compareTo(b.title);
  });

  final overdueRows =
      rows.where((r) => r.isOverdue && r.isActive).toList(growable: false);
  final quickCloseRows =
      rows.where((r) => r.quickCloseable).toList(growable: false);

  final summary = TasksWorkspaceSummary(
    active: rows.where((r) => r.isActive).length,
    overdue: rows.where((r) => r.isOverdue).length,
    today: rows.where((r) => r.isToday).length,
    matched: rows.where((r) => r.isMatched).length,
    partial: rows.where((r) => r.isPartial).length,
  );

  final dateChipLabel = summary.today > 0 || summary.overdue > 0
      ? '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}'
      : '';

  return TasksWorkspaceSnapshot(
    rows: rows,
    overdueRows: overdueRows,
    quickCloseRows: quickCloseRows,
    summary: summary,
    coverageNote:
        'Öncelik sunucuda ayrı bir alan değildir; geciken ve bugün vadeli '
        'açık görevlerin kural tabanlı göstergesidir. Uydurma verimlilik skoru '
        'veya yapay zekâ sıralaması yok — yalnızca kayıtlı vade ve durum.',
    isEmpty: rows.isEmpty,
    dateChipLabel: dateChipLabel,
  );
}

String _partialNote({
  required bool titleMissing,
  required bool dueMissing,
}) {
  final missing = <String>[];
  if (titleMissing) missing.add('başlık');
  if (dueMissing) missing.add('vade');
  if (missing.isEmpty) return '';
  return 'Eksik: ${missing.join(' · ')}';
}

String _nextAction({
  required bool done,
  required bool isOverdue,
  required bool isToday,
  required bool isMatched,
}) {
  if (done) return '';
  if (isOverdue) return 'Gecikti — tamamla veya ertele';
  if (isToday) return 'Bugün kapatılabilir';
  if (isMatched) return 'Müşteriye git';
  return '';
}

int _sortRank({
  required bool done,
  required bool isOverdue,
  required bool isToday,
  required bool isPartial,
}) {
  if (done) return 5;
  if (isOverdue) return 0;
  if (isToday) return 1;
  if (isPartial) return 2;
  return 3;
}

TaskTone _toneFor({
  required bool done,
  required bool isOverdue,
  required bool isToday,
  required bool isPartial,
  required bool isMatched,
}) {
  if (done) return TaskTone.completed;
  if (isOverdue) return TaskTone.overdue;
  if (isToday) return TaskTone.today;
  if (isPartial) return TaskTone.partial;
  if (isMatched) return TaskTone.matched;
  return TaskTone.upcoming;
}
