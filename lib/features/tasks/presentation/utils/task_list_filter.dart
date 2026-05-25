import 'package:cloud_firestore/cloud_firestore.dart';

/// Görevlerim filtre şeridi — istemci tarafı.
enum TaskListFilter {
  all,
  today,
  overdue,
  upcoming,
  completed,
}

extension TaskListFilterLabels on TaskListFilter {
  String get label => switch (this) {
        TaskListFilter.all => 'Tümü',
        TaskListFilter.today => 'Bugün',
        TaskListFilter.overdue => 'Geciken',
        TaskListFilter.upcoming => 'Yaklaşan',
        TaskListFilter.completed => 'Tamamlanan',
      };
}

/// Gerçek görev sayımları — sahte KPI yok.
class TaskListSummary {
  const TaskListSummary({
    required this.open,
    required this.today,
    required this.overdue,
    required this.upcoming,
    required this.completed,
    required this.total,
  });

  final int open;
  final int today;
  final int overdue;
  final int upcoming;
  final int completed;
  final int total;

  static const empty = TaskListSummary(
    open: 0,
    today: 0,
    overdue: 0,
    upcoming: 0,
    completed: 0,
    total: 0,
  );
}

DateTime taskListDayFloor(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

bool taskDocIsDone(Map<String, dynamic> data) => data['done'] == true;

DateTime? taskDocDueAt(Map<String, dynamic> data) {
  return (data['dueAt'] as Timestamp?)?.toDate() ??
      (data['dueDate'] as Timestamp?)?.toDate();
}

TaskListSummary computeTaskListSummary(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  DateTime today,
) =>
    computeTaskListSummaryFromData(docs.map((d) => d.data()), today);

bool matchesTaskListFilter(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
  TaskListFilter filter,
  DateTime today,
) =>
    matchesTaskDataFilter(doc.data(), filter, today);

bool matchesTaskDataFilter(
  Map<String, dynamic> data,
  TaskListFilter filter,
  DateTime today,
) {
  final done = taskDocIsDone(data);
  final dueAt = taskDocDueAt(data);
  final todayFloor = taskListDayFloor(today);

  return switch (filter) {
    TaskListFilter.all => true,
    TaskListFilter.completed => done,
    TaskListFilter.today =>
      !done &&
          dueAt != null &&
          taskListDayFloor(dueAt) == todayFloor,
    TaskListFilter.overdue =>
      !done &&
          dueAt != null &&
          taskListDayFloor(dueAt).isBefore(todayFloor),
    TaskListFilter.upcoming =>
      !done &&
          dueAt != null &&
          taskListDayFloor(dueAt).isAfter(todayFloor),
  };
}

TaskListSummary computeTaskListSummaryFromData(
  Iterable<Map<String, dynamic>> entries,
  DateTime today,
) {
  var open = 0;
  var todayCount = 0;
  var overdue = 0;
  var upcoming = 0;
  var completed = 0;
  var total = 0;
  final todayFloor = taskListDayFloor(today);

  for (final data in entries) {
    total++;
    final done = taskDocIsDone(data);
    if (done) {
      completed++;
      continue;
    }
    open++;
    final dueAt = taskDocDueAt(data);
    if (dueAt == null) continue;
    final dueDay = taskListDayFloor(dueAt);
    if (dueDay.isBefore(todayFloor)) {
      overdue++;
    } else if (dueDay == todayFloor) {
      todayCount++;
    } else {
      upcoming++;
    }
  }

  return TaskListSummary(
    open: open,
    today: todayCount,
    overdue: overdue,
    upcoming: upcoming,
    completed: completed,
    total: total,
  );
}
