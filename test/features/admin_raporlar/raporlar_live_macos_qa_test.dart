// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/providers/raporlar_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/raporlar_actions.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/widgets/raporlar_command_surface.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/widgets/raporlar_row.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen19_reports_hub/live_qa';
const _phoneSize = Size(430, 932);
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

RaporlarSnapshot _qaSnapshot() => computeRaporlarSnapshot(
      role: AppRole.brokerOwner,
      signals: const RaporlarGroundedSignals(
        teamsCount: 6,
        officeKnown: true,
        officePendingInvites: 4,
        officeIntervention: 2,
        connectionKnown: true,
        connectionIntervention: 1,
        connectionReady: 3,
      ),
    );

RaporlarSnapshot _emptySnapshot() =>
    computeRaporlarSnapshot(role: AppRole.guest);

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
  return const PremiumShellBackdrop(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RaporlarCommandSurface(),
      ),
      bottomNavigationBar: PremiumBottomNavDock(
        items: [
          AdaptiveNavItem(Icons.dashboard_rounded, ProductLabels.managerHome),
          AdaptiveNavItem(Icons.forum_rounded, ProductLabels.messageCenter),
          AdaptiveNavItem(Icons.military_tech_rounded, ProductLabels.warRoom),
          AdaptiveNavItem(Icons.call_rounded, ProductLabels.callCenter),
          AdaptiveNavItem(Icons.analytics_rounded, ProductLabels.reports),
        ],
        selectedIndex: 4,
        onTap: _noop,
      ),
    ),
  );
}

void _noop(int _) {}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealFont();
  });

  testWidgets('live macOS QA — Screen 19 header/summary/filters + rows + dock',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('reports_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _surfaceWithDock(),
      overrides: [
        raporlarSnapshotProvider
            .overrideWith((ref) => AsyncValue.data(_qaSnapshot())),
      ],
    );

    expect(find.text('Raporlar'), findsWidgets);
    expect(
      find.text('Yönetici görünümü ve operasyon yüzeyleri'),
      findsOneWidget,
    );
    expect(find.textContaining('Uydurma rapor toplamı'), findsWidgets);
    expect(find.textContaining('MÜDAHALE GEREKEN'), findsOneWidget);
    expect(find.text('Tümü'), findsWidgets);
    expect(find.text('Müdahale'), findsWidgets);
    expect(find.text('Ofis Masası'), findsWidgets);
    expect(find.text('Bağlantılar'), findsWidgets);
    expect(find.text('Müdahale gerekli'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_summary_filters_live.png');

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Kadro ve yetkiler'),
      350,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('RAPOR YÜZEYLER'), findsOneWidget);
    expect(find.text('Kadro ve yetkiler'), findsOneWidget);
    await _savePng(tester, key, '02_report_rows_live.png');

    // War Room satırını, dock'taki 'Komuta Odası' etiketiyle çakışmayan
    // satıra özgü benzersiz metinle hedefle (aksi halde çift eşleşme olur).
    const lastRowText = 'Operasyon savaş odası';
    await tester.scrollUntilVisible(
      find.text(lastRowText),
      350,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final lastRow = find.text(lastRowText);
    expect(lastRow, findsOneWidget);
    final dock = find.byType(PremiumBottomNavDock);
    expect(dock, findsOneWidget);
    expect(
      _globalBottom(tester, lastRow),
      lessThan(_globalTop(tester, dock)),
      reason: 'Son rapor yüzeyi admin dock üzerinde kalmalı',
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '05_bottom_safe_area_live.png');
  });

  testWidgets('live macOS QA — Screen 19 row actions menu', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const entry = RaporEntryViewModel(
      id: 'ofis',
      kategori: RaporKategori.ofis,
      title: 'Ofis Masası',
      scope: 'Üyeler, davetler ve bağlantılar',
      description: 'Ofis durumu ve operasyon kontrol yüzeyi',
      actionKind: RaporActionKind.route,
      readinessLabel: 'Müdahale gerekli',
      tone: RaporTone.warning,
      needsAction: true,
      attentionCount: 2,
      attentionLabel: '2 müdahale',
      searchText: 'ofis masası',
    );

    const key = Key('reports_actions_live');
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
                RaporlarRow(
                  entry: entry,
                  onTap: () {},
                  onDetail: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ofis Masası'), findsOneWidget);
    expect(find.text('2 müdahale'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Aç'), findsOneWidget);
    expect(find.text('Detay'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '03_actions_live.png');
  });

  testWidgets('live macOS QA — Screen 19 detay sheet honesty', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const entry = RaporEntryViewModel(
      id: 'baglanti',
      kategori: RaporKategori.baglanti,
      title: 'Bağlantılar',
      scope: '3 hazır platform',
      description: 'Platform durumu ve ofis entegrasyon kontrolü',
      actionKind: RaporActionKind.route,
      readinessLabel: 'Hazır',
      tone: RaporTone.success,
      needsAction: false,
      searchText: 'bağlantı',
    );

    const key = Key('reports_detail_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: const [],
      child: Builder(
        builder: (context) => PremiumShellBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    RaporlarActions.showDetailSheet(context, entry),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.textContaining('uydurma rapor toplamı'), findsOneWidget);
    expect(find.text('Yüzeyi aç'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '06_detail_sheet_live.png');
  });

  testWidgets('live macOS QA — Screen 19 empty state', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('reports_empty_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _surfaceWithDock(),
      overrides: [
        raporlarSnapshotProvider
            .overrideWith((ref) => AsyncValue.data(_emptySnapshot())),
      ],
    );

    expect(find.textContaining('Rapor yüzeyi yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '04_empty_or_partial_live.png');
  });
}
