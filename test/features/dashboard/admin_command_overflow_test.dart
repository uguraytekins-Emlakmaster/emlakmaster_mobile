import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_urgent_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size, double textScale})>[
  (name: 'iPhone SE', size: Size(320, 568), textScale: 1.0),
  (name: 'iPhone 14', size: Size(390, 844), textScale: 1.0),
  (name: 'Android compact', size: Size(360, 640), textScale: 1.0),
  (name: 'Android normal', size: Size(412, 915), textScale: 1.0),
  (name: 'macOS windowed', size: Size(1280, 800), textScale: 1.0),
  (name: 'large tablet', size: Size(1024, 1366), textScale: 1.1),
];

const _summary = AdminOfficeHealthSummary(
  activeAdvisors: 6,
  openTasks: 14,
  liveCalls: 2,
  officeAlerts: 3,
  escalations: 1,
  followUpQueue: 8,
  setupPending: 2,
);

const _urgent = [
  AdminCommandUrgentItem(
    id: 'esc',
    kind: AdminUrgentKind.escalation,
    title: 'Kritik taşıma',
    subtitle: 'Müşteri devri bekliyor',
    iconName: 'escalation',
    count: 1,
  ),
];

Future<void> _pumpChrome(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: EdgeInsets.only(
            top: 47,
            bottom: size.height > 700 ? 34 : 0,
          ),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: size.width,
              child: Column(
                children: [
                  const PremiumAdminCommandHeader(
                    title: 'Komuta Merkezi',
                    subtitle: 'Ofis sağlığı · kontrol',
                  ),
                  const PremiumAdminHealthStrip(summary: _summary),
                  const PremiumAdminIntelLines(
                    recentLine: 'Son tarama: 3 ofis uyarısı',
                    criticalLine: 'Kritik odak: 1 taşıma',
                  ),
                  const PremiumAdminUrgentSection(items: _urgent),
                ],
              ),
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
  for (final profile in _profiles) {
    testWidgets('Admin command chrome zero overflow · ${profile.name}',
        (tester) async {
      await _pumpChrome(tester, profile.size, profile.textScale);
      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumAdminHealthStrip), findsOneWidget);
      expect(find.text('DEV'), findsNothing);
    });
  }
}
