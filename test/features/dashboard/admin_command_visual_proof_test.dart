import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_urgent_section.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen9_admin';
const _phoneSize = Size(390, 844);
const _pixelRatio = 3.0;

const _summary = AdminOfficeHealthSummary(
  activeAdvisors: 5,
  openTasks: 11,
  liveCalls: 1,
  missedCalls: 2,
  officeAlerts: 4,
  escalations: 2,
  followUpQueue: 6,
  setupPending: 1,
);

const _urgent = [
  AdminCommandUrgentItem(
    id: 'esc',
    kind: AdminUrgentKind.escalation,
    title: 'Kritik taşıma',
    subtitle: 'Yüksek bütçeli müşteri devri',
    iconName: 'escalation',
    count: 1,
  ),
  AdminCommandUrgentItem(
    id: 'sync',
    kind: AdminUrgentKind.sync,
    title: 'Senkron riski',
    subtitle: '2 müşteride veri / senkron riski',
    iconName: 'sync',
    count: 2,
  ),
];

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

void main() {
  testWidgets('01 — header health urgent proof', (tester) async {
    const key = Key('cap01');
    await _pumpFrame(
      tester,
      captureKey: key,
      child: Column(
        children: [
          const PremiumAdminCommandHeader(
            title: ProductLabels.managerHome,
            subtitle: 'Ofis sağlığı · ekip aktivitesi · operasyon kontrolü',
          ),
          const PremiumAdminHealthStrip(summary: _summary),
          const PremiumAdminIntelLines(
            recentLine: 'Son tarama: 4 ofis uyarısı (1 yüksek öncelik).',
            criticalLine: 'Kritik odak: 2 yönetici taşıması (1 kritik).',
          ),
          const PremiumAdminUrgentSection(items: _urgent),
        ],
      ),
    );
    expect(find.text('DEV'), findsNothing);
    await _savePng(tester, key, '01_header_health_urgent.png');
  });

  testWidgets('02 — operational modules proof', (tester) async {
    const key = Key('cap02');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 520,
      child: Column(
        children: const [
          PremiumAdminSectionLabel(
            label: 'Operasyonel müdahale',
            secondary: 'Gerçek kuyruklar',
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PremiumSurfaceCard(
              child: Text('Gelir özeti · sıcak müşteri · senkron risk satırları'),
            ),
          ),
          PremiumAdminSectionLabel(label: 'Ofis momentumu'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PremiumSurfaceCard(
              child: Text('Aktif danışman · kaçırılan çağrı · açık iş KPI'),
            ),
          ),
        ],
      ),
    );
    await _savePng(tester, key, '02_operational_modules.png');
  });

  testWidgets('03 — actions or routes proof', (tester) async {
    const key = Key('cap03');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 280,
      child: const Column(
        children: [
          PremiumAdminSectionLabel(
            label: 'Hızlı geçiş',
            secondary: 'Komuta yüzeyleri',
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PremiumIconTile(
              icon: Icons.phone_in_talk_rounded,
              title: ProductLabels.callCenter,
              subtitle: 'Ofis çağrı akışı ve kayıtlar',
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PremiumIconTile(
              icon: Icons.analytics_rounded,
              title: ProductLabels.reports,
              subtitle: 'Kadro, performans ve içgörüler',
            ),
          ),
        ],
      ),
    );
    await _savePng(tester, key, '03_actions_or_routes.png');
  });

  testWidgets('04 — empty or preview state proof', (tester) async {
    const key = Key('cap04');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 520,
      child: const Column(
        children: [
          PremiumAdminCommandHeader(
            title: 'İçgörüler ve Kadro',
            subtitle: 'Performans · ekip özeti',
          ),
          PremiumAdminHealthStrip(summary: AdminOfficeHealthSummary.empty),
          PremiumAdminUrgentSection(items: []),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: EmptyState(
              compact: true,
              grouped: true,
              icon: Icons.analytics_outlined,
              title: 'Performans verisi henüz yok',
              subtitle: 'Çağrı kayıtları biriktikçe özet burada görünür.',
            ),
          ),
        ],
      ),
    );
    await _savePng(tester, key, '04_empty_or_preview_state.png');
  });

  testWidgets('05 — bottom nav safe area proof', (tester) async {
    const key = Key('cap05');
    await _pumpFrame(
      tester,
      captureKey: key,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Column(
          children: [
            const PremiumAdminCommandHeader(
              title: ProductLabels.managerHome,
              subtitle: 'Executive command layer',
            ),
            const PremiumAdminHealthStrip(summary: _summary),
            const Expanded(
              child: SingleChildScrollView(
                child: PremiumAdminUrgentSection(items: _urgent),
              ),
            ),
          ],
        ),
        bottomNavigationBar: PremiumBottomNavDock(
          items: const [
            AdaptiveNavItem(Icons.dashboard_rounded, ProductLabels.managerHome),
            AdaptiveNavItem(Icons.military_tech_rounded, ProductLabels.warRoom),
            AdaptiveNavItem(Icons.analytics_rounded, ProductLabels.reports),
          ],
          selectedIndex: 0,
          onTap: (_) {},
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
  });
}
