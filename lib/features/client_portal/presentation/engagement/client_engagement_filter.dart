import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_types.dart';

/// Önceden hesaplanmış kanallar üzerinde arama + filtre (build() içinde ucuz).
List<ClientEngagementEntry> filterEngagementEntries(
  List<ClientEngagementEntry> source, {
  required String query,
  required EngagementFilter filter,
}) {
  final q = query.trim().toLowerCase();
  return source
      .where((e) => _matchesSearch(e, q) && _matchesFilter(e, filter))
      .toList(growable: false);
}

bool _matchesSearch(ClientEngagementEntry e, String q) {
  if (q.isEmpty) return true;
  return e.searchText.contains(q);
}

bool _matchesFilter(ClientEngagementEntry e, EngagementFilter filter) {
  return switch (filter) {
    EngagementFilter.all => true,
    EngagementFilter.interaction => e.isInteraction,
    EngagementFilter.favorites => e.kind == EngagementKind.favorites,
    EngagementFilter.message => e.kind == EngagementKind.message,
    EngagementFilter.request => e.kind == EngagementKind.request,
    EngagementFilter.saved => e.isSaved,
    EngagementFilter.recent => e.isRecent,
    EngagementFilter.partial => e.readiness != EngagementReadiness.ready,
  };
}
