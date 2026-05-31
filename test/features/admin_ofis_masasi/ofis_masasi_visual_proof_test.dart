// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/admin_ofis_masasi_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_row.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen17_office_control';
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
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: RepaintBoundary(
          key: key,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _summary = OfisMasasiSummary(
  activeMembers: 11,
  pendingInvites: 4,
  suspendedMembers: 2,
  connectionsReady: 1,
  connectionsNeedingSetup: 2,
  interventionCount: 3,
  totalMembers: 14,
  totalInvites: 5,
  totalConnections: 3,
  connectionsKnown: true,
);

List<OfisRowViewModel> get _sampleRows => const [
      OfisRowViewModel(
        id: 'member:1',
        kind: OfisRowKind.member,
        title: 'Burak Demir',
        subtitle: 'Müdür · Üyelik',
        detailLine: 'burak@emlakmaster.com',
        statusLabel: 'Askıda',
        tone: OfisTone.warning,
        timestampLabel: '3 gün önce katıldı',
        occurredAt: null,
        needsAction: true,
        hasPartialMetadata: false,
        memberUserId: 'u1',
        canSuspend: false,
        canRemove: true,
      ),
      OfisRowViewModel(
        id: 'invite:1',
        kind: OfisRowKind.invite,
        title: 'Davet kodu · QX7K2M9P',
        subtitle: 'Danışman daveti · Ayşe Yılmaz',
        detailLine: '0/3 kullanım · Son: 30 Haz 2026',
        statusLabel: 'Bekliyor',
        tone: OfisTone.info,
        timestampLabel: '2 sa önce oluşturuldu',
        occurredAt: null,
        needsAction: false,
        hasPartialMetadata: false,
        inviteId: '1',
        inviteCode: 'QX7K2M9P',
        isActiveInvite: true,
      ),
      OfisRowViewModel(
        id: 'connection:sahibinden',
        kind: OfisRowKind.connection,
        title: 'Sahibinden.com',
        subtitle: 'İçe aktarmaya hazır (dosya) · Demir Emlak',
        detailLine: '',
        statusLabel: 'İçe aktarmaya hazır',
        tone: OfisTone.success,
        timestampLabel: '1 gün önce güncellendi',
        occurredAt: null,
        needsAction: false,
        hasPartialMetadata: false,
        connectionPlatformKey: 'sahibinden',
        connectionConfigured: true,
      ),
      OfisRowViewModel(
        id: 'connection:emlakjet',
        kind: OfisRowKind.connection,
        title: 'Emlakjet',
        subtitle: 'Kurulum başlamadı',
        detailLine: '',
        statusLabel: 'Başlamadı',
        tone: OfisTone.neutral,
        timestampLabel: 'Kurulum kaydı yok',
        occurredAt: null,
        needsAction: false,
        hasPartialMetadata: true,
        connectionPlatformKey: 'emlakjet',
        connectionConfigured: false,
      ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header summary routes proof', (tester) async {
    const key = Key('proof_header');
    await _pump(
      tester,
      key: key,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const PremiumOfisMasasiHeader(
              coverageNote:
                  'Yalnızca gerçek ofis verisi gösterilir: üyeler, davetler ve '
                  'platform kurulum kayıtları. Canlı senkron ve onboarding iddiası yok.',
            ),
            const OfisMasasiSummaryStripView(summary: _summary),
            OfisMasasiQuickRoutes(
              onCreateInvite: () {},
              onUyelikler: () {},
              onKadro: () {},
              onTeams: () {},
              onConnections: () {},
            ),
            OfisMasasiCompactSearch(
              hintText: 'Üye, davet veya bağlantı ara',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '01_header_summary_routes.png');
  });

  testWidgets('02 members invites connections proof', (tester) async {
    const key = Key('proof_rows');
    await _pump(
      tester,
      key: key,
      child: ListView(
        children: [
          const OfisMasasiSectionHeader(title: 'Üyeler', count: 1),
          OfisMasasiRow(
            viewModel: _sampleRows[0],
            onTap: () {},
            onDetail: () {},
            onKadro: () {},
            onSuspend: () {},
            onRemove: () {},
          ),
          const OfisMasasiSectionHeader(title: 'Davetler', count: 1),
          OfisMasasiRow(
            viewModel: _sampleRows[1],
            onTap: () {},
            onDetail: () {},
            onCopyCode: () {},
            onDeactivate: () {},
          ),
          const OfisMasasiSectionHeader(
            title: 'Bağlantılar',
            count: 2,
            note:
                'Canlı OAuth/otomatik senkron devrede değil; yalnızca ofis kurulum durumu gösterilir.',
          ),
          OfisMasasiRow(
            viewModel: _sampleRows[2],
            onTap: () {},
            onDetail: () {},
            onOpenConnections: () {},
          ),
          OfisMasasiRow(
            viewModel: _sampleRows[3],
            onTap: () {},
            onDetail: () {},
            onOpenConnections: () {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '02_members_invites_connections.png');
  });

  testWidgets('03 actions proof', (tester) async {
    const key = Key('proof_actions');
    await _pump(
      tester,
      key: key,
      child: OfisMasasiRow(
        viewModel: _sampleRows[0],
        onTap: () {},
        onDetail: () {},
        onKadro: () {},
        onRemove: () {},
      ),
    );
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await _savePng(tester, key, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    const key = Key('proof_empty');
    await _pump(
      tester,
      key: key,
      child: const OfisMasasiEmptyState(
        title: 'Ofis bağlantısı gerekiyor',
        message:
            'Ofis masasını açmak için önce bir ofise bağlanın.',
        actionLabel: 'Ofis alanına git',
        onAction: null,
      ),
    );
    await _savePng(tester, key, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    const key = Key('proof_bottom');
    await _pump(
      tester,
      key: key,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (_, i) => OfisMasasiRow(
                viewModel: _sampleRows[i % _sampleRows.length],
                onTap: () {},
                onDetail: () {},
              ),
            ),
          ),
          const SizedBox(height: AdminOfisMasasiTokens.bottomReserve),
        ],
      ),
    );
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });

  testWidgets('loading skeleton renders', (tester) async {
    await _pump(
      tester,
      key: const Key('skel'),
      child: const OfisMasasiLoadingSkeleton(),
    );
    expect(find.byType(OfisMasasiLoadingSkeleton), findsOneWidget);
  });
}
