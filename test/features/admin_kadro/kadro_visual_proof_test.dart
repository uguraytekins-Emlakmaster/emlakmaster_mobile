import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/admin_kadro_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_consultant_filter.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_consultant_row.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_skeleton.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen12_team';
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

const _strip = KadroHealthStrip(
  activeConsultants: 5,
  needsIntervention: 2,
  inactiveConsultants: 1,
  teamCount: 3,
  unassignedConsultants: 1,
  officeOpenTasks: 11,
  officeFollowUpQueue: 6,
  hasOfficeSignals: true,
);

final _consultants = [
  const UserDoc(uid: '1', role: 'agent', name: 'Ayşe Yılmaz', email: 'ayse@ofis.com', teamId: 't1'),
  const UserDoc(uid: '2', role: 'team_lead', name: 'Mehmet Kara', email: 'mehmet@ofis.com', teamId: 't1'),
  const UserDoc(uid: '3', role: 'agent', name: 'Zeynep Demir', email: 'zeynep@ofis.com', isActive: false),
  const UserDoc(uid: '4', role: 'agent', name: 'Burak Öztürk', email: 'burak@ofis.com'),
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
    const key = Key('kadro_01');
    await _pump(
      tester,
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumKadroHeader(),
          const PremiumKadroHealthStrip(strip: _strip),
          KadroQuickRouteRow(
            onTeams: () {},
            onReports: () {},
            onCommandCenter: () {},
          ),
          KadroCompactSearch(hintText: 'Danışman ara', onChanged: (_) {}),
          KadroFilterChips(
            selected: KadroRosterFilter.all,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_health_filters.png');
  });

  testWidgets('02 consultant rows proof', (tester) async {
    const key = Key('kadro_02');
    await _pump(
      tester,
      key: key,
      child: Column(
        children: [
          for (final u in _consultants)
            KadroConsultantRow(
              user: u,
              teamName: u.teamId == 't1' ? 'Merkez Satış' : null,
              onTap: () {},
              onEdit: () {},
              onTeamDetail: u.teamId != null ? () {} : null,
              onReports: () {},
              onCommandCenter: () {},
            ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '02_consultant_rows.png');
  });

  testWidgets('03 actions menu proof', (tester) async {
    const key = Key('kadro_03');
    await _pump(
      tester,
      key: key,
      child: KadroConsultantRow(
        user: _consultants.first,
        teamName: 'Merkez Satış',
        onTap: () {},
        onEdit: () {},
        onTeamDetail: () {},
        onReports: () {},
        onCommandCenter: () {},
      ),
    );
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Aç'), findsOneWidget);
    expect(find.text('Takım detay'), findsOneWidget);
    await _savePng(tester, key, '03_actions.png');
  });

  testWidgets('04 empty state proof', (tester) async {
    const key = Key('kadro_04');
    await _pump(
      tester,
      key: key,
      child: const KadroEmptyState(
        title: 'Danışman bulunamadı',
        message: 'Filtre sonucu boş.',
      ),
    );
    await _savePng(tester, key, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    const key = Key('kadro_05');
    await _pump(
      tester,
      key: key,
      child: Column(
        children: [
          for (final u in _consultants) ...[
            KadroConsultantRow(
              user: u,
              teamName: 'Merkez',
              onTap: () {},
              onEdit: () {},
            ),
          ],
          SizedBox(height: AdminKadroTokens.bottomReserve + 34),
        ],
      ),
    );
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });
}
