import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/admin_kadro_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/providers/kadro_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_command_surface.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen12_team/live_qa';
const _macSize = Size(1280, 800);

final _teams = [
  const TeamDoc(id: 't1', name: 'Merkez Satış', managerId: 'm1'),
  const TeamDoc(id: 't2', name: 'Sahil Bölgesi', managerId: 'm2'),
  const TeamDoc(id: 't3', name: 'Kurumsal Portföy', managerId: 'm3'),
];

List<UserDoc> _longConsultantRoster() {
  const names = [
    'Ayşe Yılmaz',
    'Mehmet Kara',
    'Zeynep Demir',
    'Burak Öztürk',
    'Selin Arslan',
    'Deniz Koç',
    'Can Aydın',
    'Elif Şahin',
    'Murat Güneş',
    'Pınar Yıldız',
    'Oğuz Kılıç',
    'Gamze Polat',
    'Emre Taş',
    'Seda Aksoy',
    'Kerem Uçar',
    'Defne Ergin',
    'Barış Çelik',
    'Melis Özkan',
    'Tolga Yavuz',
    'Aslı Karaca',
    'Hakan Doğan',
    'İrem Başaran',
    'Serkan Mutlu',
    'Nazlı Erdem',
    'Volkan Tekin',
  ];
  return [
    for (var i = 0; i < names.length; i++)
      UserDoc(
        uid: 'u$i',
        role: i == 1 ? 'team_lead' : 'agent',
        name: names[i],
        email: '${names[i].split(' ').first.toLowerCase()}@ofis.com',
        teamId: _teams[i % _teams.length].id,
        isActive: i != 2 && i != 8,
      ),
  ];
}

const _office = AdminOfficeHealthSummary(
  activeAdvisors: 22,
  openTasks: 11,
  liveCalls: 1,
  missedCalls: 3,
  officeAlerts: 2,
  highAlerts: 1,
  escalations: 2,
  criticalEscalations: 1,
  followUpQueue: 6,
  setupPending: 0,
  syncRisk: 1,
);

KadroPageSnapshot _qaSnapshot() {
  return computeKadroPageSnapshot(
    consultants: _longConsultantRoster(),
    teams: _teams,
    office: _office,
    includeOfficeSignals: true,
  );
}

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(2000));
  });
}

Widget _kadroWithDockHarness() {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0E1A),
    body: SafeArea(
      bottom: false,
      child: KadroCommandSurface(
        canEditTeamRole: true,
        onEditConsultant: (_, __) {},
      ),
    ),
    bottomNavigationBar: PremiumBottomNavDock(
      items: const [
        AdaptiveNavItem(Icons.dashboard_rounded, ProductLabels.managerHome),
        AdaptiveNavItem(Icons.military_tech_rounded, ProductLabels.warRoom),
        AdaptiveNavItem(Icons.call_rounded, ProductLabels.callCenter),
        AdaptiveNavItem(Icons.analytics_rounded, ProductLabels.reports),
      ],
      selectedIndex: 0,
      onTap: (_) {},
    ),
  );
}

List<Override> _qaOverrides() => [
      kadroPageSnapshotProvider.overrideWith(
        (ref) => AsyncValue.data(_qaSnapshot()),
      ),
      displayRoleOrNullProvider.overrideWith((ref) => AppRole.brokerOwner),
    ];

Future<void> _pumpHarness(WidgetTester tester, {required Key captureKey}) async {
  tester.view.physicalSize = _macSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _qaOverrides(),
      child: MaterialApp(
        theme: AppTheme.dark(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizationsDelegate(),
        ],
        locale: const Locale('tr'),
        home: MediaQuery(
          data: const MediaQueryData(size: _macSize),
          child: RepaintBoundary(
            key: captureKey,
            child: _kadroWithDockHarness(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

double _globalBottom(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return box.localToGlobal(Offset.zero).dy + box.size.height;
}

double _globalTop(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return box.localToGlobal(Offset.zero).dy;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live macOS QA — Screen 12 Kadro', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('kadro_live_qa');
    await _pumpHarness(tester, captureKey: key);

    // 1 — Text readability (real font glyph layout on macOS)
    expect(find.text('Kadro'), findsOneWidget);
    expect(find.text('Ekip durumu ve danışman yönetimi'), findsOneWidget);
    expect(find.textContaining('Doğrulama'), findsOneWidget);
    expect(find.text('Aktif'), findsWidgets);
    expect(find.text('Takım'), findsWidgets);
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
    expect(find.textContaining('@ofis.com'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_text_readability.png');

    // 2 — Takım filter + team sub-chips
    await tester.tap(find.text('Takım').last);
    await tester.pumpAndSettle();
    expect(find.text('Merkez Satış'), findsWidgets);
    expect(find.text('Sahil Bölgesi'), findsOneWidget);
    expect(find.text('Kurumsal Portföy'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '02_takim_sub_chips.png');

    // 3 — Row action menu (gated items for broker_owner)
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Aç'), findsOneWidget);
    expect(find.text('Düzenle'), findsOneWidget);
    expect(find.text('Takım detay'), findsWidgets);
    expect(find.text('Raporlar'), findsWidgets);
    expect(find.text('Çağrı merkezi'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await _savePng(tester, key, '03_row_menu.png');

    // 4 — Bottom dock coexistence (scroll to last row)
    await tester.tap(find.text('Tümü'));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    expect(scrollable, findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Volkan Tekin'),
      500,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Volkan Tekin'), findsOneWidget);

    final lastRow = find.text('Volkan Tekin');
    final dock = find.byType(PremiumBottomNavDock);
    expect(dock, findsOneWidget);

    final rowBottom = _globalBottom(tester, lastRow);
    final dockTop = _globalTop(tester, dock);
    expect(
      rowBottom,
      lessThan(dockTop - 8),
      reason: 'Last consultant row must sit above the admin dock',
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '04_bottom_dock_coexistence.png');

    // 5 — General density / quick routes visible without overflow at top
    await tester.drag(scrollable, const Offset(0, 4200));
    await tester.pumpAndSettle();
    expect(find.text('Ekipler'), findsOneWidget);
    expect(find.text('Raporlar'), findsWidgets);
    expect(find.text('Savaş odası'), findsOneWidget);
    expect(find.text('Çağrı merkezi'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '05_general_feel_top.png');
  });
}
