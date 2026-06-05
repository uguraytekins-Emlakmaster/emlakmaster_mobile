import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';

List<TaskRowView> filterTasksWorkspaceRows(
  List<TaskRowView> source, {
  String query = '',
  TasksWorkspaceFilter filter = TasksWorkspaceFilter.all,
}) {
  final q = query.trim().toLowerCase();

  bool matchesFilter(TaskRowView r) => switch (filter) {
        TasksWorkspaceFilter.all => true,
        TasksWorkspaceFilter.overdue => r.isOverdue,
        TasksWorkspaceFilter.today => r.isToday,
        TasksWorkspaceFilter.active => r.isActive,
        TasksWorkspaceFilter.completed => r.isCompleted,
        TasksWorkspaceFilter.partial => r.isPartial,
        TasksWorkspaceFilter.matched => r.isMatched,
        TasksWorkspaceFilter.priority => r.isPriority,
      };

  return source
      .where((r) => matchesFilter(r) && (q.isEmpty || r.searchText.contains(q)))
      .toList(growable: false);
}
