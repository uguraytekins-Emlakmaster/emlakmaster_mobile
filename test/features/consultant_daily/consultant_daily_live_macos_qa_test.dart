// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/providers/consultant_daily_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '_daily_test_fixtures.dart';

const _proofDir = 'build/screenshots/screen21_consultant_review/live_qa';
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
  return base.copyWith(
    textTheme: base.textTheme
        .apply(fontFamily: _qaFont, fontFamilyFallback: const [_qaFont]),
    primaryTextTheme: base.primaryTextTheme
        .apply(fontFamily: _qaFont, fontFamilyFallback: const [_qaFont]),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: TextStyle(fontFamily: _qaFont),
      secondaryLabelStyle: TextStyle(fontFamily: _qaFont),
    ),
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

void _noop(int _) {}

Widget _surfaceWithDock() {
  return const PremiumShellBackdrop(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ConsultantDailySurface(),
      ),
      bottomNavigationBar: PremiumBottomNavDock(
        items: [
          AdaptiveNavItem(Icons.today_rounded, 'Günüm'),
          AdaptiveNavItem(Icons.call_rounded, 'Çağrılarım'),
          AdaptiveNavItem(Icons.people_rounded, 'Müşterilerim'),
          AdaptiveNavItem(Icons.checklist_rounded, 'Görevlerim'),
          AdaptiveNavItem(Icons.more_horiz_rounded, 'Daha Fazla'),
        ],
        selectedIndex: 0,
        onTap: _noop,
      ),
    ),
  );
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Key captureKey,
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
        home: _surfaceWithDock(),
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

  testWidgets('live macOS QA — Screen 21 header/summary/filters + rows + dock',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('daily_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        consultantDailySnapshotProvider
            .overrideWith((ref) => AsyncValue.data(dailyFixtureSnapshot())),
      ],
    );

    expect(find.text('Benim Günüm'), findsWidgets);
    expect(find.textContaining('Ada'), findsWidgets);
    expect(find.textContaining('Performans skoru'), findsWidgets);
    expect(find.text('Tümü'), findsWidgets);
    expect(find.textContaining('ÖNCEL'), findsOneWidget);
    expect(find.text('Deniz Hot Investor'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_summary_filters_live.png');

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Yaklaşan sözleşme yenileme'),
      320,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Yaklaşan sözleşme yenileme'), findsOneWidget);
    await _savePng(tester, key, '02_priority_rows_live.png');

    // Dürüst kapsam notu en altta, dock üzerinde kalmalı.
    await tester.scrollUntilVisible(
      find.textContaining('AI değildir'),
      320,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final lastNote = find.textContaining('AI değildir');
    expect(lastNote, findsOneWidget);
    final dock = find.byType(PremiumBottomNavDock);
    expect(dock, findsOneWidget);
    expect(
      _globalBottom(tester, lastNote),
      lessThan(_globalTop(tester, dock)),
      reason: 'Son içerik danışman dock’u üzerinde kalmalı',
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '05_bottom_safe_area_live.png');
  });

  testWidgets('live macOS QA — Screen 21 row actions menu', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('daily_actions_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        consultantDailySnapshotProvider
            .overrideWith((ref) => AsyncValue.data(dailyFixtureSnapshot())),
      ],
    );

    // Telefonlu satır (geciken takip) → Ara/Mesaj gerçek aksiyonları görünür.
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Mehmet Yılmaz Demirkol Karaköseoğlu'),
      300,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final followRow = find.ancestor(
      of: find.text('Mehmet Yılmaz Demirkol Karaköseoğlu'),
      matching: find.byType(Padding),
    );
    final menu = find.descendant(
      of: followRow.first,
      matching: find.byIcon(Icons.more_vert_rounded),
    );
    await tester.tap(menu.first);
    await tester.pumpAndSettle();
    expect(find.text('Detay'), findsOneWidget);
    expect(find.text('Ara'), findsOneWidget);
    expect(find.text('Mesaj'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '03_actions_live.png');
  });

  testWidgets('live macOS QA — Screen 21 partial/empty coverage',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('daily_partial_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        consultantDailySnapshotProvider
            .overrideWith((ref) => AsyncValue.data(dailyEmptySnapshot())),
      ],
    );

    // Boş gün → dürüst "acil bir baskı yok" mesajı.
    expect(find.textContaining('acil bir baskı yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '04_empty_or_partial_live.png');
  });
}
