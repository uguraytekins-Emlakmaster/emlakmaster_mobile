import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/utils/war_room_intervention_model.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/widgets/war_room_intervention_surface.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/widgets/war_room_resurrection_strip.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/war_room_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen11_war_room';
const _phoneSize = Size(390, 844);
const _seSize = Size(320, 568);
const _pixelRatio = 3.0;

const _health = AdminOfficeHealthSummary(
  activeAdvisors: 4,
  openTasks: 6,
  liveCalls: 1,
  missedCalls: 3,
  officeAlerts: 2,
  highAlerts: 1,
  escalations: 2,
  criticalEscalations: 1,
  followUpQueue: 8,
  setupPending: 1,
  syncRisk: 2,
);

final _lanes = buildWarRoomPriorityLanes(health: _health);

final _interventions = buildWarRoomInterventionRows(
  escalations: const [
    ManagerEscalationItem(
      code: EscalationCode.hotNeglected,
      escalationTitleTr: 'Sıcak müşteri ihmal edildi',
      escalationDescriptionTr: '7+ gün temas yok',
      escalationPriority: EscalationPriority.critical,
      relatedCustomerId: 'cust_1',
      customerName: 'Zeynep A.',
    ),
  ],
  alerts: const [
    BrokerCustomerAlertItem(
      customerId: 'cust_2',
      customerName: 'Burak T.',
      code: BrokerAlertCode.appointmentAtRisk,
      alertTitleTr: 'Randevu riski',
      alertDescriptionTr: 'Yarın randevu, onay yok',
      priorityLevel: BrokerAlertPriority.high,
    ),
  ],
  followUp: const [],
  syncRisk: const [],
  openTasks: 6,
);

const _mockResurrectionQueue = [
  ResurrectionQueueItem(
    customerId: 'cust_r1',
    customerName: 'Selin M.',
    daysSilent: 21,
    segment: ResurrectionSegment.silent14,
  ),
  ResurrectionQueueItem(
    customerId: 'cust_r2',
    customerName: 'Deniz T.',
    daysSilent: 35,
    segment: ResurrectionSegment.silent30,
  ),
];

final _resurrectionOverride = resurrectionQueueProvider.overrideWith(
  (ref) => Stream.value(_mockResurrectionQueue),
);

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
  List<Override> overrides = const [],
  bool wrapScroll = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final body = wrapScroll
      ? SingleChildScrollView(child: child)
      : child;

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
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
                  child: body,
                ),
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

/// Gerçek WarRoomPage gövdesi: scroll + bottomReserve + resurrection + dock.
Widget _realWarRoomBottomStack({
  bool compactContent = false,
}) {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0E1A),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (!compactContent) ...[
                  const PremiumWarRoomHeader(),
                  const WarRoomCrisisStrip(summary: _health),
                ],
                WarRoomPriorityLanes(
                  lanes: _lanes.take(compactContent ? 1 : 2).toList(),
                ),
                const SizedBox(height: WarRoomTokens.bottomReserve),
              ],
            ),
          ),
          const WarRoomResurrectionStrip(),
        ],
      ),
    ),
    bottomNavigationBar: PremiumBottomNavDock(
      items: const [
        AdaptiveNavItem(Icons.dashboard_rounded, ProductLabels.managerHome),
        AdaptiveNavItem(Icons.military_tech_rounded, ProductLabels.warRoom),
        AdaptiveNavItem(Icons.call_rounded, ProductLabels.callCenter),
        AdaptiveNavItem(Icons.analytics_rounded, ProductLabels.reports),
      ],
      selectedIndex: 1,
      onTap: (_) {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 — header crisis strip proof', (tester) async {
    const key = Key('wr_cap01');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 220,
      child: const Column(
        children: [
          PremiumWarRoomHeader(),
          WarRoomCrisisStrip(summary: _health),
        ],
      ),
    );
    expect(find.text('Savaş Odası'), findsOneWidget);
    expect(find.textContaining('Doğrulama'), findsOneWidget);
    expect(find.text('Kritik'), findsOneWidget);
    await _savePng(tester, key, '01_header_crisis_strip.png');
  });

  testWidgets('02 — priority lanes proof', (tester) async {
    const key = Key('wr_cap02');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 420,
      child: Column(
        children: [
          const WarRoomSectionLabel(
            label: 'Öncelik hatları',
            secondary: 'Gerçek kuyruklar',
          ),
          WarRoomPriorityLanes(lanes: _lanes),
        ],
      ),
    );
    expect(find.text('Geciken işler'), findsOneWidget);
    expect(find.text('Kaçırılan çağrılar'), findsOneWidget);
    await _savePng(tester, key, '02_priority_lanes.png');
  });

  testWidgets('03 — intervention actions proof', (tester) async {
    const key = Key('wr_cap03');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 380,
      child: Column(
        children: [
          const WarRoomSectionLabel(
            label: 'Müdahale listesi',
            secondary: 'Ne düzeltilmeli?',
          ),
          WarRoomInterventionList(rows: _interventions),
          const WarRoomSectionLabel(label: 'Operasyon geçişi'),
          const WarRoomSecondaryRoutes(),
        ],
      ),
    );
    expect(find.text('Sıcak müşteri ihmal edildi'), findsOneWidget);
    expect(find.text(ProductLabels.callCenter), findsOneWidget);
    await _savePng(tester, key, '03_intervention_actions.png');
  });

  testWidgets('04 — partial or empty state proof', (tester) async {
    const key = Key('wr_cap04');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 480,
      child: const Column(
        children: [
          PremiumWarRoomHeader(),
          WarRoomCrisisStrip(summary: AdminOfficeHealthSummary.empty),
          WarRoomSectionLabel(label: 'Öncelik hatları'),
          WarRoomPriorityLanes(lanes: []),
          WarRoomSectionLabel(label: 'Müdahale listesi'),
          WarRoomInterventionList(rows: []),
        ],
      ),
    );
    expect(find.textContaining('sakin'), findsWidgets);
    expect(find.textContaining('% risk'), findsNothing);
    await _savePng(tester, key, '04_partial_or_empty_state.png');
  });

  testWidgets('05 — bottom safe area proof (real stack)', (tester) async {
    const key = Key('wr_cap05');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: _phoneSize.height,
      wrapScroll: false,
      overrides: [_resurrectionOverride],
      child: _realWarRoomBottomStack(compactContent: true),
    );
    expect(find.text('Geri kazanım sırası'), findsOneWidget);
    expect(find.text('Selin M. · 21g'), findsOneWidget);
    expect(find.text('Dock reserve'), findsNothing);
    expect(find.text(ProductLabels.warRoom), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });

  testWidgets('06 — full bottom stack proof', (tester) async {
    const key = Key('wr_cap06');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: _phoneSize.height,
      wrapScroll: false,
      overrides: [_resurrectionOverride],
      child: _realWarRoomBottomStack(),
    );
    expect(find.text('Savaş Odası'), findsOneWidget);
    expect(find.text('Geri kazanım sırası'), findsOneWidget);
    expect(find.text('Deniz T. · 35g'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '06_full_bottom_stack.png');
  });

  testWidgets('iPhone SE — no overflow on war room chrome', (tester) async {
    await _pumpFrame(
      tester,
      captureKey: const Key('se'),
      size: _seSize,
      height: _seSize.height,
      wrapScroll: false,
      overrides: [_resurrectionOverride],
      child: _realWarRoomBottomStack(compactContent: true),
    );
    expect(tester.takeException(), isNull);
  });
}
