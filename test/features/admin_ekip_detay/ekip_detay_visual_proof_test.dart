import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/admin_ekip_detay_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/utils/ekip_detay_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_member_row.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_skeleton.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen14_team_detail';
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

const _strip = EkipDetayHealthStrip(
  totalMembers: 6,
  activeMembers: 5,
  inactiveMembers: 1,
  interventionMembers: 2,
  teamNeedsIntervention: true,
  officeOpenTasks: 11,
  officeFollowUpQueue: 6,
  officeMissedCalls: 2,
  hasOfficeSignals: true,
);

final _members = [
  UserDoc(
    uid: 'm1',
    role: 'team_lead',
    name: 'Ayşe Yılmaz',
    email: 'ayse@emlakmaster.com',
    isActive: true,
    teamId: 't1',
  ),
  UserDoc(
    uid: 'a1',
    role: 'agent',
    name: 'Burak Demir',
    email: 'burak@emlakmaster.com',
    isActive: true,
    teamId: 't1',
  ),
  UserDoc(
    uid: 'a2',
    role: 'agent',
    name: 'Zeynep Kaya',
    email: 'zeynep@emlakmaster.com',
    isActive: false,
    teamId: 't1',
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

  testWidgets('01 header health routes proof', (tester) async {
    const key = Key('ed_01');
    await _pump(
      tester,
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumEkipDetayHeader(
            teamName: 'Merkez Satış',
            managerLine: 'Ekip lideri · Ayşe Yılmaz',
          ),
          const PremiumEkipDetayHealthStrip(strip: _strip),
          const EkipDetayOfficeNote(),
          EkipDetayQuickRouteRow(
            onKadro: () {},
            onTeams: () {},
            onReports: () {},
            onAddMember: () {},
            onCommandCenter: () {},
            onWarRoom: () {},
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_health_routes.png');
  });

  testWidgets('02 member rows proof', (tester) async {
    const key = Key('ed_02');
    await _pump(
      tester,
      key: key,
      child: Column(
        children: [
          const EkipDetaySectionHeader(title: 'Ekip üyeleri', count: 3),
          for (final m in _members)
            EkipDetayMemberRow(
              user: m,
              teamManagerId: 'm1',
              canEdit: true,
              canRemove: true,
              onTap: () {},
              onEdit: () {},
              onKadro: () {},
              onReports: () {},
              onRemove: () {},
            ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '02_member_rows.png');
  });

  testWidgets('03 actions menu proof', (tester) async {
    const key = Key('ed_03');
    await _pump(
      tester,
      key: key,
      child: EkipDetayMemberRow(
        user: _members.last,
        teamManagerId: 'm1',
        canEdit: true,
        canRemove: true,
        onTap: () {},
        onEdit: () {},
        onKadro: () {},
        onReports: () {},
        onCommandCenter: () {},
        onRemove: () {},
      ),
    );
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Aç'), findsOneWidget);
    expect(find.text('Kadroya git'), findsOneWidget);
    expect(find.text('Müdahale detay'), findsOneWidget);
    await _savePng(tester, key, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    const key = Key('ed_04');
    await _pump(
      tester,
      key: key,
      child: const EkipDetayEmptyState(
        title: 'Henüz üye yok',
        message: 'Bu ekibe danışman atayarak kadroyu oluşturabilirsiniz.',
        actionLabel: 'Üye ekle',
      ),
    );
    await _savePng(tester, key, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    const key = Key('ed_05');
    await _pump(
      tester,
      key: key,
      child: Column(
        children: [
          for (final m in _members)
            EkipDetayMemberRow(
              user: m,
              teamManagerId: 'm1',
              onTap: () {},
              onEdit: () {},
            ),
          SizedBox(height: AdminEkipDetayTokens.bottomReserve + 34),
        ],
      ),
    );
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });
}
