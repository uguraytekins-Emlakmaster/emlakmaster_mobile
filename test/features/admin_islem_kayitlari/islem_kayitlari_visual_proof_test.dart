import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/admin_islem_kayitlari_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_row.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen15_audit';
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

final _strip = IslemKayitlariHealthStrip(
  last24hCount: 5,
  criticalCount: 1,
  teamChangeCount: 2,
  consultantActionCount: 4,
  inviteCount: 3,
  warningCount: 2,
  totalEvents: 12,
  auditLogCount: 9,
  hasPartialCoverage: true,
);

List<IslemKayitlariRowViewModel> get _sampleRows => [
      IslemKayitlariRowViewModel(
        id: 'audit:1',
        title: 'Yetki değişimi — danışman rolü',
        actorLine: 'Broker Owner',
        targetLine: 'user · Burak Demir',
        detailLine: 'role: agent → team_lead',
        timestampLabel: '45 dk önce',
        occurredAt: DateTime.now().subtract(const Duration(minutes: 45)),
        severity: IslemKayitlariSeverity.critical,
        category: IslemKayitlariCategory.role,
        source: IslemKayitlariEventSource.auditLog,
        sourceLabel: 'Audit kaydı',
        categoryLabel: 'Yetki',
        suggestedFilter: IslemKayitlariFilter.critical,
        consultantId: 'u1',
        teamId: null,
        hasPartialMetadata: false,
      ),
      IslemKayitlariRowViewModel(
        id: 'invite:1',
        title: 'Davet oluşturuldu',
        actorLine: 'Ayşe Yılmaz',
        targetLine: 'zeynep@emlakmaster.com',
        detailLine: 'Rol: Danışman · Ekip ataması var',
        timestampLabel: '2 sa önce',
        occurredAt: DateTime.now().subtract(const Duration(hours: 2)),
        severity: IslemKayitlariSeverity.info,
        category: IslemKayitlariCategory.invite,
        source: IslemKayitlariEventSource.invite,
        sourceLabel: 'Davet kaydı',
        categoryLabel: 'Invite',
        suggestedFilter: IslemKayitlariFilter.invite,
        consultantId: null,
        teamId: 't1',
        hasPartialMetadata: false,
      ),
      IslemKayitlariRowViewModel(
        id: 'audit:2',
        title: 'Ekip üyesi ataması',
        actorLine: 'Genel Müdür',
        targetLine: 'Alpha Operasyon',
        detailLine: 'assign_agent_to_team',
        timestampLabel: '6 sa önce',
        occurredAt: DateTime.now().subtract(const Duration(hours: 6)),
        severity: IslemKayitlariSeverity.info,
        category: IslemKayitlariCategory.assignment,
        source: IslemKayitlariEventSource.auditLog,
        sourceLabel: 'Audit kaydı',
        categoryLabel: 'Atama',
        suggestedFilter: IslemKayitlariFilter.assignment,
        consultantId: 'u2',
        teamId: 't1',
        hasPartialMetadata: true,
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
            PremiumIslemKayitlariHeader(coverageNote: _strip.hasPartialCoverage
                ? 'Kaynaklar: audit_logs ve davet kayıtları.'
                : ''),
            PremiumIslemKayitlariHealthStrip(strip: _strip),
            IslemKayitlariQuickRouteRow(
              onKadro: () {},
              onReports: () {},
              onCommandCenter: () {},
            ),
            IslemKayitlariCompactSearch(
              hintText: 'İşlem ara (aktör, hedef, detay)',
              onChanged: (_) {},
            ),
            IslemKayitlariFilterChips(
              selected: IslemKayitlariFilter.all,
              onSelected: (_) {},
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '01_header_summary_filters.png');
  });

  testWidgets('02 audit rows proof', (tester) async {
    const key = Key('proof_rows');
    await _pump(
      tester,
      key: key,
      child: ListView.builder(
        itemCount: _sampleRows.length,
        itemBuilder: (_, i) => IslemKayitlariRow(
          viewModel: _sampleRows[i],
          onTap: () {},
          onDetail: () {},
          onConsultant: () {},
          onTeam: () {},
          onReports: () {},
          onApplyFilter: () {},
        ),
      ),
    );
    await _savePng(tester, key, '02_audit_rows.png');
  });

  testWidgets('03 actions proof', (tester) async {
    const key = Key('proof_actions');
    await _pump(
      tester,
      key: key,
      child: IslemKayitlariRow(
        viewModel: _sampleRows.first,
        onTap: () {},
        onDetail: () {},
        onConsultant: () {},
        onTeam: () {},
        onReports: () {},
        onApplyFilter: () {},
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
      child: const IslemKayitlariEmptyState(
        title: 'Henüz işlem kaydı yok',
        message:
            'Henüz kayıtlı operasyon geçmişi yok. Tam denetim kapsamı genişletildikçe admin işlemleri burada görünecek.',
        actionLabel: 'Kadroya git',
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
              itemBuilder: (_, i) => IslemKayitlariRow(
                viewModel: _sampleRows[i % _sampleRows.length],
                onTap: () {},
                onDetail: () {},
              ),
            ),
          ),
          const SizedBox(height: AdminIslemKayitlariTokens.bottomReserve),
        ],
      ),
    );
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });

  testWidgets('loading skeleton renders', (tester) async {
    await _pump(
      tester,
      key: const Key('skel'),
      child: const IslemKayitlariLoadingSkeleton(),
    );
    expect(find.byType(IslemKayitlariLoadingSkeleton), findsOneWidget);
  });
}
