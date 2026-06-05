import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/models/follow_up_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_filter.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/consultant_follow_up_chrome.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/follow_up_lead_card.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/follow_up_list_row_quick_actions.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen7_resurrection';
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

ResurrectionQueueItem _lead({
  required String id,
  required String name,
  int days = 14,
  ResurrectionSegment segment = ResurrectionSegment.silent14,
  String? phone,
  CustomerHeatLevel heat = CustomerHeatLevel.warm,
  String? nextAction,
}) {
  return ResurrectionQueueItem(
    customerId: id,
    customerName: name,
    primaryPhone: phone ?? '+905551112233',
    segment: segment,
    daysSilent: days,
    lastInteractionAt: DateTime.now().subtract(Duration(days: days)),
    nextSuggestedAction: nextAction,
    heatLevel: heat,
    heatScore: 55,
  );
}

Widget _leadCard(ResurrectionQueueItem item) {
  final snapshot = FollowUpRowSnapshot.fromItem(item);
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: FollowUpLeadCard(
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
    const key = Key('proof_follow_up_header');
    const summary = FollowUpListSummary(
      todayFollowUp: 3,
      overdue: 5,
      callback: 4,
      coldLeads: 2,
      opportunity: 1,
    );

    await _pumpFrame(
      tester,
      captureKey: key,
      size: _phoneSize,
      height: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumFollowUpPageHeader(
            title: 'Takip Merkezi',
            subtitle: 'müşteri takibi · fırsat geri kazanımı',
          ),
          const PremiumFollowUpSummaryStrip(summary: summary),
          PremiumFollowUpSearchRow(
            controller: TextEditingController(),
            hintText: 'İsim, telefon veya not ara',
          ),
          PremiumFollowUpFilterStrip(
            selected: FollowUpListFilter.overdue,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '01_header_summary_filters.png');
    expect(find.byKey(const Key('follow_up_filter_strip_scroll')), findsOneWidget);
    expect(find.text('Takip Merkezi'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('02 — lead rows proof', (tester) async {
    const key = Key('proof_follow_up_rows');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _leadCard(
              _lead(
                id: '1',
                name: 'Ayşe Demir — 30 gün sessiz',
                days: 32,
                segment: ResurrectionSegment.silent30,
                heat: CustomerHeatLevel.hot,
                nextAction: 'Fiyat görüşmesi planla',
              ),
            ),
            _leadCard(
              _lead(
                id: '2',
                name: 'Mehmet Kaya',
                days: 14,
                heat: CustomerHeatLevel.cool,
              ),
            ),
            _leadCard(
              _lead(
                id: '3',
                name: 'Telefonsuz lead',
                days: 21,
                phone: '',
                segment: ResurrectionSegment.silent14,
                heat: CustomerHeatLevel.cold,
              ),
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '02_lead_rows.png');
    expect(find.text('Ayşe Demir — 30 gün sessiz'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('03 — row actions proof', (tester) async {
    const key = Key('proof_follow_up_actions');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 220,
      child: _leadCard(
        _lead(id: 'a', name: 'Hızlı aksiyonlar — örnek lead'),
      ),
    );
    await _savePng(tester, key, '03_actions.png');
    expect(find.byType(FollowUpListRowQuickActions), findsOneWidget);
    expect(find.byIcon(Icons.call_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chat_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_task_outlined), findsOneWidget);
    expect(find.byIcon(Icons.snooze_rounded), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('04 — empty state proof', (tester) async {
    const key = Key('proof_follow_up_empty');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 540,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumFollowUpPageHeader(
            title: 'Takip Merkezi',
            subtitle: 'müşteri takibi · fırsat geri kazanımı',
          ),
          PremiumFollowUpSummaryStrip(summary: FollowUpListSummary.empty),
          EmptyState(
            premiumVisual: true,
            grouped: true,
            icon: Icons.track_changes_rounded,
            title: 'Takip bekleyen müşteri yok',
            subtitle:
                '7+ gün sessiz müşteri yok. Yeni temaslar burada görünür.',
            actionLabel: ProductLabels.myCustomers,
            outlinedActionLabel: ProductLabels.myTasks,
          ),
        ],
      ),
    );
    await _savePng(tester, key, '04_empty_state.png');
    expect(find.text('Takip bekleyen müşteri yok'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('05 — bottom nav safe area proof', (tester) async {
    const key = Key('proof_follow_up_dock');
    await _pumpFrame(
      tester,
      captureKey: key,
      size: _phoneSize,
      height: _phoneSize.height,
      child: _consultantShellDock(
        body: Column(
          children: [
            const PremiumFollowUpPageHeader(
              title: 'Takip Merkezi',
              subtitle: 'müşteri takibi · fırsat geri kazanımı',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  _leadCard(
                    _lead(
                      id: 'd1',
                      name: 'Son lead — dock altında görünür',
                    ),
                  ),
                  _leadCard(_lead(id: 'd2', name: 'İkinci satır')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
    expect(find.text('Son lead — dock altında görünür'), findsOneWidget);
    expect(find.byType(PremiumBottomNavDock), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });
}
