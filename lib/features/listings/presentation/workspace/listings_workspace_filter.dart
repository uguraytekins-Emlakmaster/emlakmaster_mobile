import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';

List<ListingWorkspaceRowView> filterListingsWorkspaceRows(
  List<ListingWorkspaceRowView> source, {
  String query = '',
  ListingsWorkspaceFilter filter = ListingsWorkspaceFilter.all,
}) {
  final q = query.trim().toLowerCase();

  bool matchesFilter(ListingWorkspaceRowView r) => switch (filter) {
        ListingsWorkspaceFilter.all => true,
        ListingsWorkspaceFilter.active => r.isActive,
        ListingsWorkspaceFilter.missing => r.isMissing,
        ListingsWorkspaceFilter.ready => r.isReady,
        ListingsWorkspaceFilter.partial => r.isPartial,
        ListingsWorkspaceFilter.attention => r.needsAttention,
        ListingsWorkspaceFilter.residential =>
          r.propertyCategory == ListingPropertyCategory.residential,
        ListingsWorkspaceFilter.land =>
          r.propertyCategory == ListingPropertyCategory.land,
        ListingsWorkspaceFilter.commercial =>
          r.propertyCategory == ListingPropertyCategory.commercial,
      };

  return source
      .where((r) => matchesFilter(r) && (q.isEmpty || r.searchText.contains(q)))
      .toList(growable: false);
}
