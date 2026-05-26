import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';
import 'package:flutter_test/flutter_test.dart';

ListingRowView _row({
  ListingSyncStatus sync = ListingSyncStatus.synced,
  String? listingType,
  String? platformStatus,
  ListingSurface surface = ListingSurface.owned,
  ListingRowKind kind = ListingRowKind.officePortfolio,
  String title = 'Test',
}) {
  return ListingRowView(
    id: '1',
    sourcePlatform: 'internal',
    sourceListingId: '1',
    isOwnedByOffice: true,
    syncStatus: sync,
    title: title,
    priceLabel: '1.000.000',
    locationLabel: 'Kadıköy',
    surface: surface,
    rowKind: kind,
    detailListingId: '1',
    listingType: listingType,
    platformStatus: platformStatus,
  );
}

void main() {
  group('computeListingListSummary', () {
    test('counts owned rows only', () {
      final rows = [
        _row(sync: ListingSyncStatus.synced),
        _row(sync: ListingSyncStatus.pending),
        _row(
          sync: ListingSyncStatus.error,
          surface: ListingSurface.marketFeed,
          kind: ListingRowKind.market,
        ),
      ];
      final s = computeListingListSummary(rows);
      expect(s.total, 2);
      expect(s.attention, greaterThanOrEqualTo(1));
    });
  });

  group('matchesListingListFilter', () {
    test('sale filter uses listingType', () {
      final sale = _row(listingType: 'Satılık');
      final rent = _row(listingType: 'Kiralık');
      expect(
        matchesListingListFilter(sale, ListingListFilter.sale, ''),
        isTrue,
      );
      expect(
        matchesListingListFilter(rent, ListingListFilter.sale, ''),
        isFalse,
      );
    });

    test('search matches title', () {
      final r = _row(title: 'Deniz manzaralı');
      expect(
        matchesListingListFilter(r, ListingListFilter.all, 'deniz'),
        isTrue,
      );
      expect(
        matchesListingListFilter(r, ListingListFilter.all, 'ankara'),
        isFalse,
      );
    });

    test('attention matches error sync', () {
      final r = _row(sync: ListingSyncStatus.error);
      expect(
        matchesListingListFilter(r, ListingListFilter.attention, ''),
        isTrue,
      );
    });
  });
}
