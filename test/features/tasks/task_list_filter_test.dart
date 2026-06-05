import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 5, 25);
  final todayTs = Timestamp.fromDate(DateTime(2026, 5, 25, 10));

  test('computeTaskListSummaryFromData counts real buckets', () {
    final entries = [
      {'done': false, 'dueAt': todayTs},
      {'done': false, 'dueAt': Timestamp.fromDate(DateTime(2026, 5, 20))},
      {'done': false, 'dueAt': Timestamp.fromDate(DateTime(2026, 5, 28))},
      {'done': true, 'dueAt': todayTs},
    ];
    final summary = computeTaskListSummaryFromData(entries, today);
    expect(summary.total, 4);
    expect(summary.open, 3);
    expect(summary.today, 1);
    expect(summary.overdue, 1);
    expect(summary.upcoming, 1);
    expect(summary.completed, 1);
  });

  test('matchesTaskDataFilter upcoming excludes today and overdue', () {
    final overdue = {
      'done': false,
      'dueAt': Timestamp.fromDate(DateTime(2026, 5, 20)),
    };
    final upcoming = {
      'done': false,
      'dueAt': Timestamp.fromDate(DateTime(2026, 5, 28)),
    };
    expect(matchesTaskDataFilter(overdue, TaskListFilter.upcoming, today),
        isFalse);
    expect(matchesTaskDataFilter(upcoming, TaskListFilter.upcoming, today),
        isTrue);
  });

  test('matchesTaskDataFilter completed only done tasks', () {
    expect(matchesTaskDataFilter({'done': true}, TaskListFilter.completed, today),
        isTrue);
    expect(matchesTaskDataFilter({'done': false}, TaskListFilter.completed, today),
        isFalse);
  });

  test('TaskListFilter labels match product copy', () {
    expect(TaskListFilter.all.label, 'Tümü');
    expect(TaskListFilter.overdue.label, 'Geciken');
    expect(TaskListFilter.completed.label, 'Tamamlanan');
  });
}
