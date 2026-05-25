import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_sort.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_source.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_record_premium_tile.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_call_center_chrome.dart';
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

CallKpiPeriodSnapshot _snapshot() {
  return CallKpiPeriodLogic.snapshotFromDocs(const [], CallKpiPeriod.thisMonth);
}

Future<void> _pumpChrome(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  addTearDown(searchController.dispose);
  addTearDown(searchFocus.dispose);

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
                const PremiumCallCenterPageHeader(
                  compact: true,
                  title: 'Çağrılarım',
                  subtitle: 'CRM çağrı merkezi',
                ),
                PremiumCallSearchRow(
                  controller: searchController,
                  focusNode: searchFocus,
                ),
                PremiumCallRecordsKpiCard(
                  snapshot: _snapshot(),
                  expanded: false,
                ),
                PremiumCallRecordsKpiCard(
                  snapshot: _snapshot(),
                  expanded: true,
                ),
                PremiumCallSourceFilterStrip(
                  selected: CallListSource.all,
                  onSelected: (_) {},
                ),
                PremiumCallQuickFilterStrip(
                  labels: const ['Tümü', 'Bugün', 'Cevapsız'],
                  selectedIndex: 0,
                  onSelected: (_) {},
                ),
                PremiumCallListToolbar(
                  sortMode: CallListSortMode.lastCall,
                  onSortChanged: (_) {},
                ),
                CallRecordPremiumTile(
                  title: 'Ahmet Yılmaz · 0532 000 00 00',
                  directionDuration: 'Giden · 02:48',
                  outcomeLabel: 'Ulaşıldı',
                  statusLabel: 'Kayıt tamam',
                  metaLine: 'Sen · 14:32',
                  leadingIcon: Icons.call_made_rounded,
                  leadingColor: Colors.blue,
                  customerLinkHint: 'Müşteri kartı yok',
                  onTap: () {},
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
  group('Consultant Calls Phase B overflow zero', () {
    for (final profile in _profiles) {
      testWidgets('chrome + compact row · ${profile.name}', (tester) async {
        await _pumpChrome(tester, profile.size, profile.textScale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
