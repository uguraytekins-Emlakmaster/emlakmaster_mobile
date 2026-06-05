import 'package:emlakmaster_mobile/features/client_portal/presentation/data/client_portal_preview_catalog.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchesClientPortalFilter', () {
    test('all filter returns every catalog row', () {
      for (final row in clientPortalPreviewCatalog) {
        expect(
          matchesClientPortalFilter(row, ClientPortalFilter.all, ''),
          isTrue,
        );
      }
    });

    test('sale filter excludes rent rows', () {
      final saleRows = clientPortalPreviewCatalog
          .where((r) => r.kind == ClientListingKind.sale);
      final rentRows = clientPortalPreviewCatalog
          .where((r) => r.kind == ClientListingKind.rent);
      for (final row in saleRows) {
        expect(
          matchesClientPortalFilter(row, ClientPortalFilter.sale, ''),
          isTrue,
        );
      }
      for (final row in rentRows) {
        expect(
          matchesClientPortalFilter(row, ClientPortalFilter.sale, ''),
          isFalse,
        );
      }
    });

    test('favorites filter is always empty (honest)', () {
      for (final row in clientPortalPreviewCatalog) {
        expect(
          matchesClientPortalFilter(row, ClientPortalFilter.favorites, ''),
          isFalse,
        );
      }
    });

    test('search matches title location and features', () {
      const row = ClientPortalPreviewListing(
        id: 'x',
        title: 'Villa Sur',
        priceLabel: '1 ₺',
        location: 'Sur merkez',
        features: 'Havuzlu',
        kind: ClientListingKind.sale,
      );
      expect(matchesClientPortalFilter(row, ClientPortalFilter.all, 'villa'), isTrue);
      expect(matchesClientPortalFilter(row, ClientPortalFilter.all, 'sur'), isTrue);
      expect(matchesClientPortalFilter(row, ClientPortalFilter.all, 'havuz'), isTrue);
      expect(matchesClientPortalFilter(row, ClientPortalFilter.all, 'xyz'), isFalse);
    });
  });

  group('computeClientPortalSummary', () {
    test('reports honest preview counts', () {
      final summary = computeClientPortalSummary(signedIn: true);
      expect(summary.favoriteCount, 0);
      expect(summary.portfolioPreviewCount, clientPortalPreviewCatalog.length);
      expect(summary.messageState, ClientPortalMessageState.preview);
      expect(summary.appointmentState, ClientPortalAppointmentState.preview);
      expect(summary.profileReady, isTrue);
    });

    test('profile not ready when signed out', () {
      final summary = computeClientPortalSummary(signedIn: false);
      expect(summary.profileReady, isFalse);
    });
  });
}
