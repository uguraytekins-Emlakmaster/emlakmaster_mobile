// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/providers/uyelikler_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_command_surface.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_row.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen16_membership/live_qa';
const _phoneSize = Size(430, 932);
const _officeId = 'qa-office';
const _qaFont = 'QAReal';

const _fontPaths = <String>[
  '/System/Library/Fonts/Supplemental/Arial.ttf',
  '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
];

/// Gerçek metin render'ı için sistem fontunu (Arial — tam Türkçe glif) yükler.
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

UyelikRowViewModel _activeMember(String userId, String name, String detail,
    {String role = 'Danışman'}) {
  return UyelikRowViewModel(
    id: 'member:$userId',
    kind: UyelikKind.member,
    title: name,
    subtitle: '$role · Üyelik',
    detailLine: detail,
    statusLabel: 'Aktif üye',
    durum: UyelikDurum.active,
    tone: UyelikTone.success,
    timestampLabel: '12 gün önce katıldı',
    occurredAt: DateTime(2026, 5, 19),
    needsAction: false,
    hasPartialMetadata: false,
    memberUserId: userId,
    canModerate: true,
    canSuspend: true,
    canRemove: true,
  );
}

UyeliklerPageSnapshot _qaSnapshot() {
  return UyeliklerPageSnapshot(
    rows: [
      const UyelikRowViewModel(
        id: 'member:burak',
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
        memberUserId: 'burak',
        canModerate: true,
        canSuspend: false,
        canRemove: true,
      ),
      const UyelikRowViewModel(
        id: 'invite:trb',
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
        inviteId: 'trb',
        inviteCode: 'TRB49K2A',
        isActiveInvite: true,
      ),
      const UyelikRowViewModel(
        id: 'invite:qx',
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
        inviteId: 'qx',
        inviteCode: 'QX7K2M9P',
        isActiveInvite: true,
      ),
      _activeMember('zeynep', 'Zeynep Kaya', 'zeynep@emlakmaster.com'),
      _activeMember('ada', 'Ada Lovelace', 'ada@emlakmaster.com',
          role: 'Müdür'),
      for (var i = 1; i <= 10; i++)
        _activeMember('u$i', 'Danışman $i', 'danisman$i@emlakmaster.com'),
    ],
    strip: const UyeliklerSummaryStrip(
      pendingInvites: 4,
      acceptedInvites: 6,
      expiredInvites: 2,
      activeMembers: 11,
      interventionCount: 3,
      totalMembers: 14,
      totalInvites: 12,
    ),
    isEmpty: false,
    hasInvites: true,
    hasMembers: true,
    coverageNote:
        'Yalnızca gerçek davet ve üyelik kayıtları gösterilir. Onboarding '
        'ilerlemesi cihaz-yereldir; sunucuda izlenmediği için burada gösterilmez.',
  );
}

UyeliklerPageSnapshot _emptySnapshot() {
  return const UyeliklerPageSnapshot(
    rows: [],
    strip: UyeliklerSummaryStrip.empty,
    isEmpty: true,
    hasInvites: false,
    hasMembers: false,
    coverageNote:
        'Henüz davet veya üyelik kaydı yok. Davet oluşturdukça ofis kadrosu '
        'burada görünecek.',
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
        child: UyeliklerCommandSurface(officeId: _officeId),
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
        // builder ile sarınca açılan popup overlay'i de yakalanır.
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
      uyeliklerSnapshotProvider(_officeId)
          .overrideWithValue(AsyncValue.data(_qaSnapshot())),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealFont();
  });

  testWidgets('live macOS QA — Screen 16 header/rows/bottom', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('uyelikler_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _surfaceWithDock(),
      overrides: _populatedOverrides(),
    );

    // 01 — header + honesty note + summary strip + search + filters + quick routes
    expect(find.text('Üyelikler / Davetler'), findsOneWidget);
    expect(find.text('Davet, onboarding ve katılım takibi'), findsOneWidget);
    expect(find.textContaining('sunucuda izlenmediği'), findsOneWidget);
    expect(find.text('Bekleyen'), findsWidgets);
    expect(find.text('Aktif üye'), findsWidgets);
    expect(find.text('Müdahale'), findsWidgets);
    expect(find.text('Yeni davet'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_summary_filters_live.png');

    // 02 — multiple invite/member rows + status chips + readable text
    expect(find.text('Burak Demir'), findsOneWidget);
    expect(find.text('Davet kodu · QX7K2M9P'), findsOneWidget);
    expect(find.text('Zeynep Kaya'), findsOneWidget);
    expect(find.text('Bekliyor'), findsWidgets);
    expect(find.text('Askıda'), findsWidgets);
    expect(find.textContaining('MÜDAHALE GEREKEN'), findsOneWidget);
    await _savePng(tester, key, '02_membership_rows_live.png');

    // 05 — last row above the real dock (populated, scrolled to bottom)
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Danışman 10'),
      400,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    final lastRow = find.text('Danışman 10');
    expect(lastRow, findsOneWidget);
    final dock = find.byType(PremiumBottomNavDock);
    expect(dock, findsOneWidget);
    expect(
      _globalBottom(tester, lastRow),
      lessThan(_globalTop(tester, dock) - 8),
      reason: 'Son satır admin dock üzerinde kalmalı',
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '05_bottom_safe_area_live.png');
  });

  testWidgets('live macOS QA — Screen 16 row actions menu', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('uyelikler_actions_live');
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
                UyelikRow(
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

    // Geçerli olduğunda görünen kapılı (gated) aksiyonlar:
    expect(find.text('Detay'), findsOneWidget);
    expect(find.text('Kadroya git'), findsOneWidget);
    expect(find.text('Askıya al'), findsOneWidget);
    expect(find.text('Kaldır'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '03_actions_live.png');
  });

  testWidgets('live macOS QA — Screen 16 empty state', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('uyelikler_empty_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _surfaceWithDock(),
      overrides: [
        uyeliklerSnapshotProvider(_officeId)
            .overrideWithValue(AsyncValue.data(_emptySnapshot())),
      ],
    );

    expect(find.text('Henüz davet veya üyelik yok'), findsOneWidget);
    expect(find.textContaining('Davet oluşturdukça'), findsWidgets);
    expect(find.text('Yeni davet oluştur'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '04_empty_or_partial_live.png');
  });
}
