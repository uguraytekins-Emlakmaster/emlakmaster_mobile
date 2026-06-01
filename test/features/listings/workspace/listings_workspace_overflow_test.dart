import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_workspace_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size})>[
  (name: 'iPhone SE', size: Size(320, 568)),
  (name: 'iPhone 14', size: Size(390, 844)),
  (name: 'Android compact', size: Size(360, 640)),
  (name: 'macOS', size: Size(1280, 800)),
];

ListingWorkspaceRowView _rowView() {
  final snap = computeListingsWorkspaceSnapshot(
    [
      ListingRowView(
        id: 'l1',
        sourcePlatform: 'internal',
        sourceListingId: 'l1',
        isOwnedByOffice: true,
        syncStatus: ListingSyncStatus.synced,
        title: 'Uzun ilan başlığı — satılık daire merkezi konum',
        priceLabel: '4.250.000',
        locationLabel: 'İstanbul Kadıköy Moda',
        surface: ListingSurface.owned,
        rowKind: ListingRowKind.officePortfolio,
        detailListingId: 'l1',
        listingType: 'Satılık Konut',
        platformStatus: 'published',
      ),
    ],
    now: DateTime(2024, 6, 15, 12),
    canManage: true,
  );
  return snap.rows.first;
}

Future<void> _pumpRow(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: ListingsWorkspaceRow(
            row: _rowView(),
            onTap: () {},
            onMenu: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final p in _profiles) {
    testWidgets('row overflow — ${p.name}', (tester) async {
      await _pumpRow(tester, p.size);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('summary strip', (tester) async {
    final snap = computeListingsWorkspaceSnapshot(
      [
        ListingRowView(
          id: 'a',
          sourcePlatform: 'internal',
          sourceListingId: 'a',
          isOwnedByOffice: true,
          syncStatus: ListingSyncStatus.synced,
          title: 'Test',
          priceLabel: '1',
          locationLabel: 'İzmir',
          surface: ListingSurface.owned,
          rowKind: ListingRowKind.officePortfolio,
          detailListingId: 'a',
        ),
      ],
      now: DateTime(2024, 6, 15),
      canManage: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: ListingsWorkspaceSummaryStrip(summary: snap.summary),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
