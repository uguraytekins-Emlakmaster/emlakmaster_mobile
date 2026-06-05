import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';

/// İlanlarım filtre şeridi — yalnızca gerçek satır alanları.
enum ListingListFilter {
  all,
  active,
  draft,
  published,
  sale,
  rent,
  attention,
}

extension ListingListFilterLabels on ListingListFilter {
  String get label => switch (this) {
        ListingListFilter.all => 'Tümü',
        ListingListFilter.active => 'Aktif',
        ListingListFilter.draft => 'Taslak',
        ListingListFilter.published => 'Yayında',
        ListingListFilter.sale => 'Satılık',
        ListingListFilter.rent => 'Kiralık',
        ListingListFilter.attention => 'Dikkat',
      };
}

/// Portföy özet şeridi — gerçek sayımlar.
class ListingListSummary {
  const ListingListSummary({
    required this.active,
    required this.draft,
    required this.published,
    required this.attention,
    required this.total,
  });

  final int active;
  final int draft;
  final int published;
  final int attention;
  final int total;

  static const empty = ListingListSummary(
    active: 0,
    draft: 0,
    published: 0,
    attention: 0,
    total: 0,
  );
}

bool listingRowNeedsAttention(ListingRowView row) {
  return row.syncStatus == ListingSyncStatus.error ||
      row.syncStatus == ListingSyncStatus.stale ||
      row.syncStatus == ListingSyncStatus.pending;
}

bool listingRowIsPublished(ListingRowView row) {
  final st = row.platformStatus?.trim().toLowerCase();
  if (st != null && st.isNotEmpty) {
    if (st.contains('publish') ||
        st.contains('active') ||
        st.contains('live') ||
        st.contains('yayin') ||
        st == 'yayında') {
      return true;
    }
    if (st.contains('draft') || st.contains('taslak') || st.contains('pending')) {
      return false;
    }
  }
  return row.syncStatus == ListingSyncStatus.synced;
}

bool listingRowIsDraft(ListingRowView row) {
  if (row.syncStatus == ListingSyncStatus.pending) return true;
  final st = row.platformStatus?.trim().toLowerCase();
  if (st != null &&
      (st.contains('draft') || st.contains('taslak') || st.contains('pending'))) {
    return true;
  }
  return row.syncStatus == ListingSyncStatus.unknown &&
      row.rowKind == ListingRowKind.officePortfolio;
}

bool listingRowIsActive(ListingRowView row) {
  if (row.surface != ListingSurface.owned) return false;
  return row.syncStatus == ListingSyncStatus.synced && !listingRowNeedsAttention(row);
}

bool _listingTypeMatchesSale(String? raw) {
  if (raw == null || raw.trim().isEmpty) return false;
  final l = raw.trim().toLowerCase();
  return l.contains('sale') ||
      l.contains('satılık') ||
      l.contains('satilik') ||
      l == 'sell';
}

bool _listingTypeMatchesRent(String? raw) {
  if (raw == null || raw.trim().isEmpty) return false;
  final l = raw.trim().toLowerCase();
  return l.contains('rent') ||
      l.contains('kiralık') ||
      l.contains('kiralik') ||
      l.contains('lease');
}

bool listingRowMatchesSearch(ListingRowView row, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  bool hit(String? s) => s != null && s.toLowerCase().contains(q);
  return hit(row.title) ||
      hit(row.locationLabel) ||
      hit(row.priceLabel) ||
      hit(row.sourcePlatform) ||
      hit(row.listingType) ||
      hit(sourcePlatformDisplayLabel(row.sourcePlatform));
}

bool matchesListingListFilter(
  ListingRowView row,
  ListingListFilter filter,
  String searchQuery,
) {
  if (!listingRowMatchesSearch(row, searchQuery)) return false;
  return switch (filter) {
    ListingListFilter.all => true,
    ListingListFilter.active => listingRowIsActive(row),
    ListingListFilter.draft => listingRowIsDraft(row),
    ListingListFilter.published => listingRowIsPublished(row),
    ListingListFilter.sale => _listingTypeMatchesSale(row.listingType),
    ListingListFilter.rent => _listingTypeMatchesRent(row.listingType),
    ListingListFilter.attention => listingRowNeedsAttention(row),
  };
}

ListingListSummary computeListingListSummary(Iterable<ListingRowView> rows) {
  var active = 0;
  var draft = 0;
  var published = 0;
  var attention = 0;
  var total = 0;

  for (final row in rows) {
    if (row.surface != ListingSurface.owned) continue;
    total++;
    if (listingRowNeedsAttention(row)) attention++;
    if (listingRowIsDraft(row)) draft++;
    if (listingRowIsPublished(row)) published++;
    if (listingRowIsActive(row)) active++;
  }

  return ListingListSummary(
    active: active,
    draft: draft,
    published: published,
    attention: attention,
    total: total,
  );
}
