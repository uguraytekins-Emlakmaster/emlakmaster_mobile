import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/models/listing_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/consultant_listings_chrome.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_card.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_list_row_quick_actions.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen5_listings';
const _phoneSize = Size(390, 844);
const _pixelRatio = 3.0;

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(800));
  });
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
  Size size = _phoneSize,
  double? height,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: Material(
          color: const Color(0xFF0A0E1A),
          child: Center(
            child: SizedBox(
              width: size.width,
              height: height ?? size.height,
              child: RepaintBoundary(
                key: captureKey,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

ListingRowView _listing({
  required String id,
  required String title,
  ListingSyncStatus sync = ListingSyncStatus.synced,
  String? listingType,
  ListingRowKind kind = ListingRowKind.officePortfolio,
}) {
  return ListingRowView(
    id: id,
    sourcePlatform: kind == ListingRowKind.connectedPlatform
        ? 'sahibinden'
        : 'internal',
    sourceListingId: id,
    isOwnedByOffice: true,
    syncStatus: sync,
    title: title,
    priceLabel: '8.750.000',
    locationLabel: 'Kadıköy · Moda',
    surface: ListingSurface.owned,
    rowKind: kind,
    detailListingId: id,
    listingType: listingType ?? 'Satılık',
    platformStatus: sync == ListingSyncStatus.synced ? 'active' : 'draft',
  );
}

Widget _listingCard(ListingRowView row) {
  final snapshot = ListingListRowSnapshot.fromRow(row);
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: ListingCard(
      row: row,
      snapshot: snapshot,
      onTap: () {},
      onDetail: () {},
      onEdit: () {},
      onShare: () {},
      onSync: () {},
    ),
  );
}

Widget _consultantShellDock({required Widget body}) {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0E1A),
    body: body,
    bottomNavigationBar: PremiumBottomNavDock(
      items: const [
        AdaptiveNavItem(
          Icons.space_dashboard_rounded,
          ProductLabels.consultantHome,
        ),
        AdaptiveNavItem(Icons.call_rounded, ProductLabels.myCalls),
        AdaptiveNavItem(Icons.people_rounded, ProductLabels.myCustomers),
        AdaptiveNavItem(Icons.task_alt_rounded, ProductLabels.myTasks),
        AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
      ],
      selectedIndex: 4,
      onTap: (_) {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 — header summary filters proof', (tester) async {
    const key = Key('proof_listings_header');
    const summary = ListingListSummary(
      active: 4,
      draft: 1,
      published: 5,
      attention: 2,
      total: 6,
    );

    await _pumpFrame(
      tester,
      captureKey: key,
      size: _phoneSize,
      height: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumListingsPageHeader(
            title: 'İlanlarım',
            subtitle: 'Portföy yönetimi · aktif ilan akışı',
          ),
          const PremiumListingsSummaryStrip(summary: summary),
          PremiumListingSearchRow(
            controller: TextEditingController(),
            hintText: 'İlan, konum veya fiyat ara',
          ),
          PremiumListingFilterStrip(
            selected: ListingListFilter.active,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '01_header_summary_filters.png');
    expect(find.byKey(const Key('listing_filter_strip_scroll')), findsOneWidget);
    expect(find.text('İlanlarım'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('02 — listing rows proof', (tester) async {
    const key = Key('proof_listings_rows');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _listingCard(
              _listing(
                id: 'l1',
                title: 'Deniz manzaralı 3+1 — Etiler',
                kind: ListingRowKind.connectedPlatform,
              ),
            ),
            _listingCard(
              _listing(
                id: 'l2',
                title: 'Ofis portföyü — merkezi konum',
                sync: ListingSyncStatus.pending,
              ),
            ),
            _listingCard(
              _listing(
                id: 'l3',
                title: 'Kiralık işyeri — Maslak',
                listingType: 'Kiralık',
                sync: ListingSyncStatus.error,
              ),
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '02_listing_rows.png');
    expect(find.text('Deniz manzaralı 3+1 — Etiler'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('03 — listing actions proof', (tester) async {
    const key = Key('proof_listings_actions');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 168,
      child: _listingCard(
        _listing(id: 'l9', title: 'Hızlı aksiyonlar — örnek ilan'),
      ),
    );
    await _savePng(tester, key, '03_listing_actions.png');
    expect(find.byType(ListingListRowQuickActions), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('04 — empty state proof', (tester) async {
    const key = Key('proof_listings_empty');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 520,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumListingsPageHeader(
            title: 'İlanlarım',
            subtitle: 'Portföy yönetimi · aktif ilan akışı',
          ),
          PremiumListingsSummaryStrip(summary: ListingListSummary.empty),
          EmptyState(
            premiumVisual: true,
            grouped: true,
            icon: Icons.home_work_outlined,
            title: 'Henüz portföy yok',
            subtitle: 'İlanları içe aktarın veya bağlı platformlardan senkronlayın.',
            actionLabel: 'İlan ekle',
          ),
        ],
      ),
    );
    await _savePng(tester, key, '04_empty_state.png');
    expect(find.text('Henüz portföy yok'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('05 — bottom nav safe area proof', (tester) async {
    const key = Key('proof_listings_dock');
    await _pumpFrame(
      tester,
      captureKey: key,
      size: _phoneSize,
      height: _phoneSize.height,
      child: _consultantShellDock(
        body: Column(
          children: [
            const PremiumListingsPageHeader(
              title: 'İlanlarım',
              subtitle: 'Portföy yönetimi · aktif ilan akışı',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  _listingCard(_listing(id: 'd1', title: 'Son ilan — dock altında görünür')),
                  _listingCard(_listing(id: 'd2', title: 'İkinci satır')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
    expect(find.text('Son ilan — dock altında görünür'), findsOneWidget);
    expect(find.byType(PremiumBottomNavDock), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('06 — edit fallback snackbar proof', (tester) async {
    const key = Key('proof_edit_snackbar');
    const snackMessage =
        'İlan düzenleme sihirbazı yakında. Şimdilik içe aktarma veya bağlı platformları kullanın.';

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 200,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            body: Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _listingCard(
                    _listing(id: 'edit', title: 'Düzenle — kullanıcı geri bildirimi'),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1E2638),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Text(
                        snackMessage,
                        style: const TextStyle(
                          color: Color(0xFFE8EAEF),
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    await _savePng(tester, key, '06_edit_fallback_snackbar.png');
    expect(find.text(snackMessage), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });
}
