import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_sort.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_source.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_record_premium_tile.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_operating_card.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_call_center_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen2_calls';
const _size = Size(390, 844);

CallKpiPeriodSnapshot _kpiSnapshot() =>
    CallKpiPeriodLogic.snapshotFromDocs(const [], CallKpiPeriod.thisMonth);

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(1000));
  });
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
  double height = 520,
}) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: _size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: Material(
          color: const Color(0xFF0A0E1A),
          child: Center(
            child: SizedBox(
              width: _size.width,
              height: height,
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
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 — KPI card proof', (tester) async {
    const key = Key('proof_kpi');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 280,
      child: PremiumCallRecordsKpiCard(
        snapshot: _kpiSnapshot(),
        expanded: true,
        onPeriodTap: () {},
        onDetailTap: () {},
        onToggleExpanded: () {},
      ),
    );
    await _savePng(tester, key, '01_kpi_card.png');
    expect(find.textContaining('FIGMA'), findsNothing);
    expect(find.textContaining('phase_a'), findsNothing);
    expect(find.textContaining('UI v2 active'), findsNothing);
  });

  testWidgets('02 — search + filters proof', (tester) async {
    const key = Key('proof_filters');
    final searchController = TextEditingController();
    final searchFocus = FocusNode();
    addTearDown(searchController.dispose);
    addTearDown(searchFocus.dispose);

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumCallSearchRow(
            controller: searchController,
            focusNode: searchFocus,
          ),
          PremiumCallSourceFilterStrip(
            selected: CallListSource.all,
            onSelected: (_) {},
          ),
          PremiumCallQuickFilterStrip(
            labels: const ['Tümü', 'Bugün', 'Cevapsız', 'Geri aranacak'],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '02_search_filters.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('03 — toolbar proof', (tester) async {
    const key = Key('proof_toolbar');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 72,
      child: PremiumCallListToolbar(
        sortMode: CallListSortMode.lastCall,
        onSortChanged: (_) {},
        trailing: TextButton(
          onPressed: () {},
          child: const Text('Seç'),
        ),
      ),
    );
    await _savePng(tester, key, '03_toolbar.png');
  });

  testWidgets('04 — compact list rows proof', (tester) async {
    const key = Key('proof_list');
    final rows = [
      ('Ahmet Yılmaz', 'Giden · 02:48', 'Ulaşıldı', Icons.call_made_rounded),
      ('Ayşe Demir', 'Gelen · 01:12', 'Cevapsız', Icons.call_received_rounded),
      ('0532 111 22 33', 'Giden · 00:45', 'Geri arama', Icons.call_made_rounded),
      ('Mehmet Kaya', 'Gelen · 05:01', 'Randevu', Icons.call_received_rounded),
    ];

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in rows)
            CrmCallOperatingCard(
              dense: true,
              child: CallRecordPremiumTile(
                title: r.$1,
                directionDuration: r.$2,
                outcomeLabel: r.$3,
                leadingIcon: r.$4,
                leadingColor: Colors.teal,
                metaLine: 'Sen · 14:32',
                onTap: () {},
              ),
            ),
        ],
      ),
    );
    await _savePng(tester, key, '04_compact_list_rows.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('05 — slidable action proof', (tester) async {
    const key = Key('proof_slidable');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 96,
      child: Slidable(
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) {},
              backgroundColor: const Color(0xFF2E7D4A),
              foregroundColor: Colors.white,
              icon: Icons.call_rounded,
              label: 'Ara',
            ),
          ],
        ),
        child: CrmCallOperatingCard(
          dense: true,
          child: CallRecordPremiumTile(
            title: 'Slidable · Ara aksiyonu',
            directionDuration: 'Giden · 02:48',
            outcomeLabel: 'Ulaşıldı',
            leadingIcon: Icons.call_made_rounded,
            leadingColor: Colors.blue,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.drag(find.byType(Slidable), const Offset(120, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    await _savePng(tester, key, '05_slidable_ara.png');
    expect(find.text('Ara'), findsWidgets);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('05b — slidable İşlem proof', (tester) async {
    const key = Key('proof_slidable_islem');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 96,
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.24,
          children: [
            SlidableAction(
              onPressed: (_) {},
              backgroundColor: const Color(0xFF3D5AFE),
              foregroundColor: Colors.white,
              icon: Icons.bolt_rounded,
              label: 'İşlem',
            ),
          ],
        ),
        child: CrmCallOperatingCard(
          dense: true,
          child: CallRecordPremiumTile(
            title: 'Slidable · İşlem aksiyonu',
            directionDuration: 'Gelen · 01:12',
            outcomeLabel: 'Ulaşıldı',
            leadingIcon: Icons.call_received_rounded,
            leadingColor: Colors.green,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.drag(find.byType(Slidable), const Offset(-140, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    await _savePng(tester, key, '05_slidable_islem.png');
    expect(find.text('İşlem'), findsWidgets);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('06 — bottom nav + list safe inset proof', (tester) async {
    const key = Key('proof_nav');
    const scaffoldKey = Key('proof_nav_scaffold');

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 560,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF0A0E1A),
        body: Builder(
          builder: (context) {
            final bottomInset =
                DashboardLayoutTokens.contentScrollBottomInset(context);
            return ListView(
          padding: EdgeInsets.only(bottom: bottomInset),
          children: List.generate(
            6,
            (i) => CrmCallOperatingCard(
              dense: true,
              child: CallRecordPremiumTile(
                title: 'Kayıt ${i + 1} · Müşteri adı',
                directionDuration: 'Gelen · 01:0$i',
                outcomeLabel: 'Ulaşıldı',
                leadingIcon: Icons.call_received_rounded,
                leadingColor: Colors.green,
                onTap: () {},
              ),
            ),
          ),
        );
          },
        ),
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
          selectedIndex: 1,
          onTap: (_) {},
        ),
      ),
    );
    await _savePng(tester, key, '06_bottom_nav_safe_area.png');
    expect(tester.takeException(), isNull);
  });
}
