import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';

List<FollowUpRowView> filterFollowUpWorkspaceRows(
  List<FollowUpRowView> source, {
  String query = '',
  FollowUpWorkspaceFilter filter = FollowUpWorkspaceFilter.all,
}) {
  final q = query.trim().toLowerCase();

  bool matchesFilter(FollowUpRowView r) => switch (filter) {
        FollowUpWorkspaceFilter.all => true,
        FollowUpWorkspaceFilter.overdue => r.isOverdue,
        FollowUpWorkspaceFilter.today => r.isToday,
        FollowUpWorkspaceFilter.active => r.isActive,
        FollowUpWorkspaceFilter.partial => r.isPartial,
        FollowUpWorkspaceFilter.matched => r.isMatched,
        FollowUpWorkspaceFilter.priority => r.isPriority,
      };

  return source
      .where((r) => matchesFilter(r) && (q.isEmpty || r.searchText.contains(q)))
      .toList(growable: false);
}
