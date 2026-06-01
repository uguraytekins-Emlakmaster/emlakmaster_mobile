import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';

/// Saf, build-güvenli filtre + arama.
List<CallRowView> filterCallsWorkspaceRows(
  List<CallRowView> source, {
  String query = '',
  CallsWorkspaceFilter filter = CallsWorkspaceFilter.all,
}) {
  final q = query.trim().toLowerCase();

  bool matchesFilter(CallRowView r) => switch (filter) {
        CallsWorkspaceFilter.all => true,
        CallsWorkspaceFilter.today => r.isToday,
        CallsWorkspaceFilter.callback => r.needsCallback,
        CallsWorkspaceFilter.matched => r.isMatched,
        CallsWorkspaceFilter.partial => r.isPartial,
        CallsWorkspaceFilter.unanswered => r.isUnanswered,
        CallsWorkspaceFilter.outgoing => r.isOutgoing,
        CallsWorkspaceFilter.incoming => r.isIncoming,
      };

  return source
      .where((r) => matchesFilter(r) && (q.isEmpty || r.searchText.contains(q)))
      .toList(growable: false);
}
