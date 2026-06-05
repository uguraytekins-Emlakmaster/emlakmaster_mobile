// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/admin_uyelikler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_row.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen16_membership';
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

const _strip = UyeliklerSummaryStrip(
  pendingInvites: 4,
  acceptedInvites: 6,
  expiredInvites: 2,
  activeMembers: 11,
  interventionCount: 3,
  totalMembers: 14,
  totalInvites: 12,
);

List<UyelikRowViewModel> get _sampleRows => const [
      UyelikRowViewModel(
        id: 'member:1',
        kind: UyelikKind.member,
        title: 'Burak Demir',
        subtitle: 'Müdür · Üyelik',
        detailLine: 'burak@emlakmaster.com',
        statusLabel: 'Askıda',
        durum: UyelikDurum.suspended,
        tone: UyelikTone.warning,
        timestampLabel: '3 gün önce katıldı',
        occurredAt: null,
        needsAction: true,
        hasPartialMetadata: false,
        memberUserId: 'u1',
        canModerate: true,
        canSuspend: false,
        canRemove: true,
      ),
      UyelikRowViewModel(
        id: 'invite:1',
        kind: UyelikKind.invite,
        title: 'Davet kodu · QX7K2M9P',
        subtitle: 'Danışman daveti · Ayşe Yılmaz',
        detailLine: '0/3 kullanım · Son: 30 Haz 2026',
        statusLabel: 'Bekliyor',
        durum: UyelikDurum.pending,
        tone: UyelikTone.info,
        timestampLabel: '2 sa önce oluşturuldu',
        occurredAt: null,
        needsAction: false,
        hasPartialMetadata: false,
        inviteId: '1',
        inviteCode: 'QX7K2M9P',
        isActiveInvite: true,
      ),
      UyelikRowViewModel(
        id: 'member:2',
        kind: UyelikKind.member,
        title: 'Zeynep Kaya',
        subtitle: 'Danışman · Üyelik',
        detailLine: 'zeynep@emlakmaster.com',
        statusLabel: 'Aktif üye',
        durum: UyelikDurum.active,
        tone: UyelikTone.success,
        timestampLabel: '12 gün önce katıldı',
        occurredAt: null,
        needsAction: false,
        hasPartialMetadata: false,
        memberUserId: 'u2',
        canModerate: true,
        canSuspend: true,
        canRemove: true,
      ),
      UyelikRowViewModel(
        id: 'invite:2',
        kind: UyelikKind.invite,
        title: 'Davet kodu · TRB49K2A',
        subtitle: 'Yönetici daveti · Genel Müdür',
        detailLine: '2/2 kullanım',
        statusLabel: 'Kontenjan doldu',
        durum: UyelikDurum.accepted,
        tone: UyelikTone.warning,
        timestampLabel: '5 gün önce oluşturuldu',
        occurredAt: null,
        needsAction: true,
        hasPartialMetadata: true,
        inviteId: '2',
        inviteCode: 'TRB49K2A',
        isActiveInvite: true,
      ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header summary filters proof', (tester) async {
    const key = Key('proof_header');
    await _pump(
      tester,
      key: key,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const PremiumUyeliklerHeader(
              coverageNote:
                  'Yalnızca gerçek davet ve üyelik kayıtları gösterilir. '
                  'Onboarding ilerlemesi cihaz-yereldir; sunucuda izlenmez.',
            ),
            const PremiumUyeliklerSummaryStrip(strip: _strip),
            UyeliklerQuickRouteRow(
              onCreateInvite: () {},
              onOfficeAdmin: () {},
              onKadro: () {},
            ),
            UyeliklerCompactSearch(
              hintText: 'Üye veya davet ara (isim, kod, rol)',
              onChanged: (_) {},
            ),
            UyeliklerFilterChips(
              selected: UyeliklerFilter.all,
              onSelected: (_) {},
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '01_header_summary_filters.png');
  });

  testWidgets('02 membership rows proof', (tester) async {
    const key = Key('proof_rows');
    await _pump(
      tester,
      key: key,
      child: ListView.builder(
        itemCount: _sampleRows.length,
        itemBuilder: (_, i) => UyelikRow(
          viewModel: _sampleRows[i],
          onTap: () {},
          onDetail: () {},
          onCopyCode: () {},
          onDeactivate: () {},
          onCreateInvite: () {},
          onKadro: () {},
          onSuspend: () {},
          onRemove: () {},
        ),
      ),
    );
    await _savePng(tester, key, '02_membership_rows.png');
  });

  testWidgets('03 actions proof', (tester) async {
    const key = Key('proof_actions');
    await _pump(
      tester,
      key: key,
      child: UyelikRow(
        viewModel: _sampleRows[2],
        onTap: () {},
        onDetail: () {},
        onKadro: () {},
        onSuspend: () {},
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
      child: const UyeliklerEmptyState(
        title: 'Henüz davet veya üyelik yok',
        message:
            'Henüz davet veya üyelik kaydı yok. Davet oluşturdukça ofis kadrosu burada görünecek.',
        actionLabel: 'Yeni davet oluştur',
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
              itemBuilder: (_, i) => UyelikRow(
                viewModel: _sampleRows[i % _sampleRows.length],
                onTap: () {},
                onDetail: () {},
              ),
            ),
          ),
          const SizedBox(height: AdminUyeliklerTokens.bottomReserve),
        ],
      ),
    );
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });

  testWidgets('loading skeleton renders', (tester) async {
    await _pump(
      tester,
      key: const Key('skel'),
      child: const UyeliklerLoadingSkeleton(),
    );
    expect(find.byType(UyeliklerLoadingSkeleton), findsOneWidget);
  });
}
