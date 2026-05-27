import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/models/follow_up_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_filter.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/consultant_follow_up_chrome.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/follow_up_lead_card.dart';
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

ResurrectionQueueItem _sampleItem() => ResurrectionQueueItem(
      customerId: 'c-long-id',
      customerName: 'Ahmet Yılmaz — uzun isim taşmasın diye test',
      primaryPhone: '+905551112233',
      segment: ResurrectionSegment.silent30,
      daysSilent: 32,
      lastInteractionAt: DateTime.now().subtract(const Duration(days: 32)),
      nextSuggestedAction: 'Fiyat teklifi ve randevu — detaylı takip notu',
      lastCallSummary: 'Müşteri 3+1 daire için geri dönüş bekliyor',
      heatLevel: CustomerHeatLevel.hot,
      heatScore: 78,
    );

Future<void> _pumpChrome(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final item = _sampleItem();
  final snapshot = FollowUpRowSnapshot.fromItem(item);

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
                const PremiumFollowUpPageHeader(
                  title: 'Takip Merkezi',
                  subtitle: 'müşteri takibi · fırsat geri kazanımı',
                ),
                PremiumFollowUpSummaryStrip(
                  summary: const FollowUpListSummary(
                    todayFollowUp: 2,
                    overdue: 5,
                    callback: 4,
                    coldLeads: 3,
                    opportunity: 1,
                  ),
                ),
                PremiumFollowUpFilterStrip(
                  selected: FollowUpListFilter.all,
                  onSelected: (_) {},
                ),
                FollowUpLeadCard(
                  item: item,
                  snapshot: snapshot,
                  onTap: () {},
                  onCall: () {},
                  onWhatsApp: () {},
                  onOpenCustomer: () {},
                  onCreateTask: () {},
                  onSnooze: () {},
                  onDetail: () {},
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
  group('Consultant Follow-up overflow zero', () {
    for (final profile in _profiles) {
      testWidgets('chrome + dense row · ${profile.name}', (tester) async {
        await _pumpChrome(tester, profile.size, profile.textScale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
