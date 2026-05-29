import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/data/client_portal_preview_catalog.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/models/client_listing_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_listing_tile.dart';
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

Future<void> _pumpChrome(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final listing = clientPortalPreviewCatalog.first;
  final snapshot = ClientListingRowSnapshot.fromPreview(listing);
  final summary = computeClientPortalSummary(signedIn: true);

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
                const PremiumClientPortalHeader(
                  title: 'Hoş geldiniz',
                  subtitle: 'Size özel portföy · güvenilir danışman deneyimi',
                ),
                PremiumClientSummaryStrip(summary: summary),
                PremiumClientPortalSearchRow(
                  controller: TextEditingController(),
                ),
                PremiumClientPortalFilterStrip(
                  selected: ClientPortalFilter.all,
                  onSelected: (_) {},
                ),
                ClientPortalListingTile(
                  listing: listing,
                  snapshot: snapshot,
                  onInspect: () {},
                  onFavorite: () {},
                  onMessage: () {},
                  onAppointment: () {},
                  onShare: () {},
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
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final profile in _profiles) {
    testWidgets('no overflow on ${profile.name}', (tester) async {
      await _pumpChrome(tester, profile.size, profile.textScale);
      expect(tester.takeException(), isNull);
    });
  }
}
