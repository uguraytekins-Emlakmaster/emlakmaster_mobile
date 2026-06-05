import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/admin_ekipler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_team_filter.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/widgets/ekipler_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/widgets/ekipler_skeleton.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/widgets/ekipler_team_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen13_teams';
const _phone390 = Size(390, 844);

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(800));
  });
}

const _strip = EkiplerHealthStrip(
  activeTeams: 4,
  totalConsultants: 18,
  interventionTeams: 2,
  unassignedConsultants: 3,
  officeOpenTasks: 11,
  officeFollowUpQueue: 6,
  officeMissedCalls: 2,
  hasOfficeSignals: true,
);

final _teams = [
  const EkiplerTeamViewModel(
    team: TeamDoc(id: 't1', name: 'Merkez Satış', managerId: 'm1'),
    stats: EkiplerTeamRosterStats(
      totalMembers: 6,
      activeMembers: 5,
      inactiveMembers: 1,
      isEmpty: false,
      allMembersInactive: false,
      needsIntervention: false,
      hasManager: true,
    ),
    managerName: 'Ayşe Yılmaz',
    managerRoleLabel: 'Ekip lideri',
  ),
  const EkiplerTeamViewModel(
    team: TeamDoc(id: 't2', name: 'Sahil Bölgesi', managerId: 'm2'),
    stats: EkiplerTeamRosterStats(
      totalMembers: 0,
      activeMembers: 0,
      inactiveMembers: 0,
      isEmpty: true,
      allMembersInactive: false,
      needsIntervention: true,
      hasManager: true,
    ),
    managerName: 'Mehmet Kara',
    managerRoleLabel: 'Ofis yöneticisi',
  ),
  const EkiplerTeamViewModel(
    team: TeamDoc(id: 't3', name: 'Kurumsal Portföy', managerId: 'm3'),
    stats: EkiplerTeamRosterStats(
      totalMembers: 4,
      activeMembers: 2,
      inactiveMembers: 2,
      isEmpty: false,
      allMembersInactive: false,
      needsIntervention: true,
      hasManager: true,
    ),
    managerName: 'Zeynep Demir',
    managerRoleLabel: 'Ekip lideri',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required Key key,
  required Widget child,
  Size size = _phone390,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
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
          child: SingleChildScrollView(
            child: RepaintBoundary(key: key, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header health filters proof', (tester) async {
    const key = Key('ekip_01');
    await _pump(
      tester,
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumEkiplerHeader(),
          const PremiumEkiplerHealthStrip(strip: _strip),
          EkiplerQuickRouteRow(
            onKadro: () {},
            onReports: () {},
            onCommandCenter: () {},
          ),
          EkiplerCompactSearch(hintText: 'Ekip ara', onChanged: (_) {}),
          EkiplerFilterChips(
            selected: EkiplerTeamFilter.all,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_health_filters.png');
  });

  testWidgets('02 team rows proof', (tester) async {
    const key = Key('ekip_02');
    await _pump(
      tester,
      key: key,
      child: Column(
        children: [
          for (final t in _teams)
            EkiplerTeamRow(
              viewModel: t,
              detailed: false,
              onTap: () {},
              onKadro: () {},
              onReports: () {},
              onAssign: () {},
            ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '02_team_rows.png');
  });

  testWidgets('03 actions menu proof', (tester) async {
    const key = Key('ekip_03');
    await _pump(
      tester,
      key: key,
      child: EkiplerTeamRow(
        viewModel: _teams.first,
        detailed: true,
        onTap: () {},
        onKadro: () {},
        onReports: () {},
        onAssign: () {},
        onCommandCenter: () {},
      ),
    );
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Aç'), findsOneWidget);
    expect(find.text('Kadroyu gör'), findsOneWidget);
    await _savePng(tester, key, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    const key = Key('ekip_04');
    await _pump(
      tester,
      key: key,
      child: const EkiplerEmptyState(
        title: 'Henüz ekip yok',
        message: 'İlk ekibinizi oluşturarak kadroyu yapılandırın.',
      ),
    );
    await _savePng(tester, key, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    const key = Key('ekip_05');
    await _pump(
      tester,
      key: key,
      child: Column(
        children: [
          for (final t in _teams) ...[
            EkiplerTeamRow(
              viewModel: t,
              detailed: false,
              onTap: () {},
              onKadro: () {},
              onReports: () {},
            ),
          ],
          SizedBox(height: AdminEkiplerTokens.bottomReserve + 34),
        ],
      ),
    );
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });
}
