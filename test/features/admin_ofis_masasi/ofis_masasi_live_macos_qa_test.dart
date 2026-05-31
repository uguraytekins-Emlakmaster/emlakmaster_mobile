// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/providers/ofis_masasi_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_command_surface.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_row.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen17_office_control/live_qa';
const _phoneSize = Size(430, 932);
const _officeId = 'qa-office';
const _qaFont = 'QAReal';

const _fontPaths = <String>[
  '/System/Library/Fonts/Supplemental/Arial.ttf',
  '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
];

Future<bool> _loadRealFont() async {
  final loader = FontLoader(_qaFont);
  var any = false;
  for (final p in _fontPaths) {
    final f = File(p);
    if (!f.existsSync()) continue;
    final bytes = await f.readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    any = true;
  }
  if (any) await loader.load();
  return any;
}

ThemeData _qaTheme() {
  final base = AppTheme.dark();
  TextStyle withFont(TextStyle? s) => (s ?? const TextStyle())
      .copyWith(fontFamily: _qaFont, fontFamilyFallback: const [_qaFont]);
  return base.copyWith(
    textTheme: base.textTheme
        .apply(fontFamily: _qaFont, fontFamilyFallback: const [_qaFont]),
    primaryTextTheme: base.primaryTextTheme
        .apply(fontFamily: _qaFont, fontFamilyFallback: const [_qaFont]),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: withFont(base.chipTheme.labelStyle),
      secondaryLabelStyle: withFont(base.chipTheme.secondaryLabelStyle),
    ),
  );
}

OfisRowViewModel _activeMember(String userId, String name, String detail,
    {String role = 'Danışman'}) {
  return OfisRowViewModel(
    id: 'member:$userId',
    kind: OfisRowKind.member,
    title: name,
    subtitle: '$role · Üyelik',
    detailLine: detail,
    statusLabel: 'Aktif üye',
    tone: OfisTone.success,
    timestampLabel: '12 gün önce katıldı',
    occurredAt: DateTime(2026, 5, 19),
    needsAction: false,
    hasPartialMetadata: false,
    memberUserId: userId,
    canSuspend: true,
    canRemove: true,
  );
}

OfisRowViewModel _connection(
  String key,
  String name,
  String status,
  String subtitle,
  OfisTone tone, {
  bool needsAction = false,
  bool configured = true,
}) {
  return OfisRowViewModel(
    id: 'connection:$key',
    kind: OfisRowKind.connection,
    title: name,
    subtitle: subtitle,
    detailLine: '',
    statusLabel: status,
    tone: tone,
    timestampLabel: configured ? '1 gün önce güncellendi' : 'Kurulum kaydı yok',
    occurredAt: configured ? DateTime(2026, 5, 30) : null,
    needsAction: needsAction,
    hasPartialMetadata: !configured,
    connectionPlatformKey: key,
    connectionConfigured: configured,
  );
}

const _summary = OfisMasasiSummary(
  activeMembers: 12,
  pendingInvites: 3,
  suspendedMembers: 1,
  connectionsReady: 1,
  connectionsNeedingSetup: 2,
  interventionCount: 3,
  totalMembers: 13,
  totalInvites: 4,
  totalConnections: 3,
  connectionsKnown: true,
);

const _coverageNote =
    'Yalnızca gerçek ofis verisi gösterilir: üyeler, davetler ve platform '
    'kurulum kayıtları. Canlı senkron ve onboarding iddiası yok.';
const _connectionsNote =
    'Canlı OAuth/otomatik senkron devrede değil; yalnızca ofis kurulum durumu gösterilir.';

OfisMasasiSnapshot _qaSnapshot() {
  return OfisMasasiSnapshot(
    members: [
      const OfisRowViewModel(
        id: 'member:burak',
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
        memberUserId: 'burak',
        canSuspend: false,
        canRemove: true,
      ),
      _activeMember('zeynep', 'Zeynep Kaya', 'zeynep@emlakmaster.com'),
      _activeMember('ada', 'Ada Lovelace', 'ada@emlakmaster.com', role: 'Müdür'),
      for (var i = 1; i <= 10; i++)
        _activeMember('u$i', 'Danışman $i', 'danisman$i@emlakmaster.com'),
    ],
    invites: [
      const OfisRowViewModel(
        id: 'invite:qx',
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
        inviteId: 'qx',
        inviteCode: 'QX7K2M9P',
        isActiveInvite: true,
      ),
    ],
    connections: [
      _connection(
        'sahibinden',
        'Sahibinden.com',
        'İçe aktarmaya hazır',
        'İçe aktarmaya hazır (dosya) · Demir Emlak',
        OfisTone.success,
      ),
      _connection(
        'hepsiemlak',
        'Hepsiemlak',
        'Eksik kurulum',
        'Kurulum tamamlanmadı · temel bilgiler eksik',
        OfisTone.warning,
        needsAction: true,
      ),
      _connection(
        'emlakjet',
        'Emlakjet',
        'Başlamadı',
        'Kurulum başlamadı',
        OfisTone.neutral,
        configured: false,
      ),
    ],
    summary: _summary,
    coverageNote: _coverageNote,
    connectionsNote: _connectionsNote,
    connectionsKnown: true,
    isEmpty: false,
  );
}

OfisMasasiSnapshot _partialSnapshot() {
  return OfisMasasiSnapshot(
    members: const [],
    invites: const [],
    connections: [
      _connection('sahibinden', 'Sahibinden.com', 'Başlamadı',
          'Kurulum başlamadı', OfisTone.neutral,
          configured: false),
      _connection('hepsiemlak', 'Hepsiemlak', 'Başlamadı',
          'Kurulum başlamadı', OfisTone.neutral,
          configured: false),
      _connection('emlakjet', 'Emlakjet', 'Başlamadı', 'Kurulum başlamadı',
          OfisTone.neutral,
          configured: false),
    ],
    summary: const OfisMasasiSummary(
      activeMembers: 0,
      pendingInvites: 0,
      suspendedMembers: 0,
      connectionsReady: 0,
      connectionsNeedingSetup: 3,
      interventionCount: 0,
      totalMembers: 0,
      totalInvites: 0,
      totalConnections: 3,
      connectionsKnown: true,
    ),
    coverageNote:
        'Henüz üye veya davet kaydı yok. Davet oluşturdukça ofis kadrosu burada görünecek. '
        '$_coverageNote',
    connectionsNote: _connectionsNote,
    connectionsKnown: true,
    isEmpty: true,
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

Widget _surfaceWithDock() {
  return PremiumShellBackdrop(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: const SafeArea(
        bottom: false,
        child: OfisMasasiCommandSurface(officeId: _officeId),
      ),
      bottomNavigationBar: PremiumBottomNavDock(
        items: const [
          AdaptiveNavItem(Icons.dashboard_rounded, ProductLabels.managerHome),
          AdaptiveNavItem(Icons.forum_rounded, ProductLabels.messageCenter),
          AdaptiveNavItem(Icons.military_tech_rounded, ProductLabels.warRoom),
          AdaptiveNavItem(Icons.call_rounded, ProductLabels.callCenter),
          AdaptiveNavItem(Icons.analytics_rounded, ProductLabels.reports),
        ],
        selectedIndex: 4,
        onTap: (_) {},
      ),
    ),
  );
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
  required List<Override> overrides,
  Size size = _phoneSize,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: _qaTheme(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizationsDelegate(),
        ],
        locale: const Locale('tr'),
        builder: (context, app) => RepaintBoundary(
          key: captureKey,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: size),
            child: app!,
          ),
        ),
        home: child,
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

List<Override> _populatedOverrides() => [
      ofisMasasiSnapshotProvider(_officeId)
          .overrideWithValue(AsyncValue.data(_qaSnapshot())),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealFont();
  });

  testWidgets('live macOS QA — Screen 17 header/summary/routes',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('ofis_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _surfaceWithDock(),
      overrides: _populatedOverrides(),
    );

    expect(find.text('Ofis Masası'), findsOneWidget);
    expect(find.text('Ofis durumu, üyeler ve bağlantılar'), findsOneWidget);
    expect(find.textContaining('Canlı senkron'), findsWidgets);
    expect(find.text('Aktif üye'), findsWidgets);
    expect(find.text('Bekleyen davet'), findsWidgets);
    expect(find.text('Bağlantı hazır'), findsWidgets);
    expect(find.text('Yeni davet'), findsWidgets);
    // Üyeler bölümünün başı (müdahale gereken üye ilk sırada).
    expect(find.text('Burak Demir'), findsOneWidget);
    expect(find.text('Askıda'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_summary_routes_live.png');

    final scrollable = find.byType(Scrollable).first;

    // 02 — davet ve bağlantı satırları (uzun liste; bölüme kaydır).
    await tester.scrollUntilVisible(
      find.text('Davet kodu · QX7K2M9P'),
      400,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Davet kodu · QX7K2M9P'), findsOneWidget);
    await _savePng(tester, key, '02_members_invites_connections_live.png');

    await tester.scrollUntilVisible(
      find.text('Sahibinden.com'),
      400,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sahibinden.com'), findsOneWidget);
    expect(find.textContaining('BAĞLANTILAR'), findsOneWidget);

    // 05 — last connection above the real dock (scrolled to bottom)
    await tester.scrollUntilVisible(
      find.text('Emlakjet'),
      400,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    final lastRow = find.text('Emlakjet');
    expect(lastRow, findsOneWidget);
    final dock = find.byType(PremiumBottomNavDock);
    expect(dock, findsOneWidget);
    expect(
      _globalBottom(tester, lastRow),
      lessThan(_globalTop(tester, dock)),
      reason: 'Son satır admin dock üzerinde kalmalı',
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '05_bottom_safe_area_live.png');
  });

  testWidgets('live macOS QA — Screen 17 row actions menu', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('ofis_actions_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: const [],
      child: PremiumShellBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ListView(
              children: [
                OfisMasasiRow(
                  viewModel: _activeMember(
                    'zeynep',
                    'Zeynep Kaya',
                    'zeynep@emlakmaster.com',
                  ),
                  onTap: () {},
                  onDetail: () {},
                  onKadro: () {},
                  onSuspend: () {},
                  onRemove: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Detay'), findsOneWidget);
    expect(find.text('Kadroya git'), findsOneWidget);
    expect(find.text('Askıya al'), findsOneWidget);
    expect(find.text('Kaldır'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '03_actions_live.png');
  });

  testWidgets('live macOS QA — Screen 17 empty/partial state', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('ofis_empty_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _surfaceWithDock(),
      overrides: [
        ofisMasasiSnapshotProvider(_officeId)
            .overrideWithValue(AsyncValue.data(_partialSnapshot())),
      ],
    );

    expect(find.textContaining('Henüz ofis üyesi yok'), findsOneWidget);
    expect(find.textContaining('Açık davet yok'), findsOneWidget);
    expect(find.textContaining('BAĞLANTILAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '04_empty_or_partial_live.png');
  });
}
