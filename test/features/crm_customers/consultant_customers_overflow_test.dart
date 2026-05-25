import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_list_heat_filter.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/consultant_customers_chrome.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_card.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
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

CustomerEntity _entity() => CustomerEntity(
      id: 'c1',
      fullName: 'Ayşe Demir',
      primaryPhone: '+905321112233',
      lastInteractionAt: DateTime.now().subtract(const Duration(days: 2)),
      nextSuggestedAction: 'Tekrar ara',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

CustomerListRowSnapshot _row() => CustomerListRowSnapshot(
      crmHeat: computeCustomerHeat(_entity()),
      showBrokerAlert: false,
      syncDelayedRisk: false,
    );

Future<void> _pumpChrome(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final searchController = TextEditingController();
  addTearDown(searchController.dispose);

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
                const PremiumCustomersPageHeader(
                  title: 'Müşterilerim',
                  subtitle: 'İlişki portföyü — arama ve sıcaklık',
                ),
                PremiumCustomerSearchRow(
                  controller: searchController,
                  hintText: 'Müşteri ara',
                ),
                PremiumCustomerHeatFilterStrip(
                  selected: CustomerListHeatFilter.hot,
                  onSelected: (_) {},
                ),
                CustomerCard(
                  customer: _entity(),
                  row: _row(),
                  onTap: () {},
                  onCall: () {},
                  onMessage: () {},
                  onWhatsApp: () {},
                  onOpenDetail: () {},
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
  group('Consultant Customers Phase C overflow zero', () {
    for (final profile in _profiles) {
      testWidgets('chrome + dense row · ${profile.name}', (tester) async {
        await _pumpChrome(tester, profile.size, profile.textScale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
