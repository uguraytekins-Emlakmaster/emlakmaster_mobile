import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2024, 6, 15, 12);

ListingRowView _row({
  required String id,
  String title = 'Daire satılık',
  String price = '2.500.000',
  String location = 'Kadıköy',
  String? imageUrl,
  String? listingType,
  ListingSyncStatus sync = ListingSyncStatus.synced,
  String? platformStatus,
}) {
  return ListingRowView(
    id: id,
    sourcePlatform: 'internal',
    sourceListingId: id,
    isOwnedByOffice: true,
    syncStatus: sync,
    title: title,
    priceLabel: price,
    locationLabel: location,
    imageUrl: imageUrl,
    surface: ListingSurface.owned,
    rowKind: ListingRowKind.officePortfolio,
    detailListingId: id,
    listingType: listingType,
    platformStatus: platformStatus,
  );
}

void main() {
  group('computeListingsWorkspaceSnapshot', () {
    test('summary gerçek sayımlar', () {
      final snap = computeListingsWorkspaceSnapshot(
        [
          _row(id: 'a', platformStatus: 'published'),
          _row(id: 'b', title: 'X', price: '—', location: '—'),
          _row(
            id: 'c',
            title: 'Villa',
            imageUrl: null,
            listingType: 'konut',
          ),
        ],
        now: _now,
        canManage: true,
      );
      expect(snap.summary.active, greaterThanOrEqualTo(1));
      expect(snap.summary.missing, 1);
      expect(snap.rows.length, 3);
    });

    test('eksik üst sıralama', () {
      final snap = computeListingsWorkspaceSnapshot(
        [
          _row(id: 'ok', platformStatus: 'published'),
          _row(id: 'bad', title: '', price: '—', location: '—'),
        ],
        now: _now,
        canManage: false,
      );
      expect(snap.rows.first.id, 'bad');
    });

    test('coverageNote dürüst — skor yok', () {
      final snap = computeListingsWorkspaceSnapshot(
        [_row(id: 'a')],
        now: _now,
        canManage: true,
      );
      expect(snap.coverageNote, contains('skor'));
      expect(snap.coverageNote, contains('AI'));
    });

    test('konut kategorisi', () {
      final snap = computeListingsWorkspaceSnapshot(
        [_row(id: 'k', listingType: 'Satılık Konut')],
        now: _now,
        canManage: true,
      );
      expect(
        snap.rows.single.propertyCategory,
        ListingPropertyCategory.residential,
      );
    });

    test('hazır — yayında ve eksiksiz', () {
      final snap = computeListingsWorkspaceSnapshot(
        [
          _row(
            id: 'ready',
            platformStatus: 'published',
            imageUrl: 'https://example.com/a.jpg',
          ),
        ],
        now: _now,
        canManage: true,
      );
      expect(snap.readyRows, isNotEmpty);
    });
  });

  group('filterListingsWorkspaceRows', () {
    late List<ListingWorkspaceRowView> rows;

    setUp(() {
      rows = computeListingsWorkspaceSnapshot(
        [
          _row(id: 'a', listingType: 'arsa'),
          _row(id: 'b', title: '', price: '—', location: '—'),
          _row(
            id: 'c',
            sync: ListingSyncStatus.error,
            platformStatus: 'published',
          ),
        ],
        now: _now,
        canManage: true,
      ).rows;
    });

    test('eksik filtresi', () {
      final out = filterListingsWorkspaceRows(
        rows,
        filter: ListingsWorkspaceFilter.missing,
      );
      expect(out.every((r) => r.isMissing), isTrue);
    });

    test('dikkat filtresi', () {
      final out = filterListingsWorkspaceRows(
        rows,
        filter: ListingsWorkspaceFilter.attention,
      );
      expect(out.every((r) => r.needsAttention), isTrue);
    });

    test('arsa filtresi', () {
      final out = filterListingsWorkspaceRows(
        rows,
        filter: ListingsWorkspaceFilter.land,
      );
      expect(out.single.id, 'a');
    });
  });
}
