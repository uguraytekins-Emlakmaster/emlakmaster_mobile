import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/models/listing_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/consultant_listings_chrome.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size, double textScale})>[
  (name: 'iPhone SE', size: Size(320, 568), textScale: 1.0),
  (name: 'iPhone 14', size: Size(390, 844), textScale: 1.0),
  (name: 'iPhone 15 Pro', size: Size(393, 852), textScale: 1.15),
  (name: 'Android compact', size: Size(360, 640), textScale: 1.0),
  (name: 'Android normal', size: Size(412, 915), textScale: 1.0),
  (name: 'macOS windowed', size: Size(1280, 800), textScale: 1.0),
  (name: 'iPad tablet', size: Size(834, 1194), textScale: 1.0),
  (name: 'large tablet', size: Size(1024, 1366), textScale: 1.1),
];

ListingRowView _sampleRow() => const ListingRowView(
      id: 'p1',
      sourcePlatform: 'sahibinden',
      sourceListingId: 'ext-1',
      isOwnedByOffice: true,
      syncStatus: ListingSyncStatus.synced,
      title: 'Boğaz manzaralı 3+1 daire — uzun başlık taşmasın',
      priceLabel: '12.500.000',
      locationLabel: 'Beşiktaş · Etiler',
      imageUrl: null,
      surface: ListingSurface.owned,
      rowKind: ListingRowKind.connectedPlatform,
      detailListingId: 'p1',
      listingType: 'Satılık',
      platformStatus: 'active',
    );

Future<void> _pumpChrome(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final row = _sampleRow();
  final snapshot = ListingListRowSnapshot.fromRow(row);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: EdgeInsets.only(bottom: size.height > 700 ? 34 : 0),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PremiumListingsPageHeader(
                  title: 'İlanlarım',
                  subtitle: 'Portföy yönetimi · aktif ilan akışı',
                ),
                PremiumListingsSummaryStrip(
                  summary: const ListingListSummary(
                    active: 3,
                    draft: 1,
                    published: 4,
                    attention: 1,
                    total: 5,
                  ),
                ),
                PremiumListingFilterStrip(
                  selected: ListingListFilter.all,
                  onSelected: (_) {},
                ),
                ListingCard(
                  row: row,
                  snapshot: snapshot,
                  onTap: () {},
                  onDetail: () {},
                  onEdit: () {},
                  onShare: () {},
                  onSync: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('Consultant Listings Phase 5 overflow zero', () {
    for (final profile in _profiles) {
      testWidgets('chrome + dense row · ${profile.name}', (tester) async {
        await _pumpChrome(tester, profile.size, profile.textScale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
