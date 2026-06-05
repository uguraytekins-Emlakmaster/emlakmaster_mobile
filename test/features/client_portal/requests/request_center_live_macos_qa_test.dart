// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/providers/request_center_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/widgets/request_center_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen23_client_requests/live_qa';
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
  );
}

RequestCenterSnapshot _qaSnapshot() => computeRequestCenterSnapshot(
      signedIn: true,
      displayName: 'Ada Yılmaz',
    );

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
        child: RequestCenterSurface(),
      ),
      bottomNavigationBar: PremiumBottomNavDock(
        items: [
          AdaptiveNavItem(Icons.search_rounded, 'Keşfet'),
          AdaptiveNavItem(Icons.favorite_rounded, ProductLabels.favorites),
          AdaptiveNavItem(Icons.chat_rounded, ProductLabels.messages),
          AdaptiveNavItem(
              Icons.assignment_outlined, ProductLabels.requestCenter),
          AdaptiveNavItem(Icons.person_rounded, ProductLabels.profile),
        ],
        selectedIndex: 3,
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

  testWidgets('live macOS QA — Screen 23 header/summary/filters + rows + dock',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('request_center_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        requestCenterSnapshotProvider
            .overrideWith((ref) => AsyncValue.data(_qaSnapshot())),
      ],
    );

    expect(find.text('Talep Merkezi'), findsWidgets);
    expect(find.textContaining('Ada Yılmaz'), findsWidgets);
    expect(find.textContaining('sunucuda'), findsWidgets);
    expect(find.text('Tümü'), findsWidgets);
    expect(find.text('Yakında'), findsWidgets);
    expect(find.text('Talep oluştur'), findsWidgets);
    expect(find.text('Danışmana ulaş'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_summary_filters.png');

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Tercihlerim'),
      320,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Tercihlerim'), findsOneWidget);
    await _savePng(tester, key, '02_request_rows.png');

    // Dürüst kapsam notu (Kayıtlı talepler) görünür.
    await tester.scrollUntilVisible(
      find.textContaining('uydurma talep gösterilmez'),
      320,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final lastNote = find.textContaining('uydurma talep gösterilmez');
    expect(lastNote, findsOneWidget);
    final dock = find.byType(PremiumBottomNavDock);
    expect(dock, findsOneWidget);
    expect(
      _globalBottom(tester, lastNote),
      lessThan(_globalTop(tester, dock)),
      reason: 'Son içerik müşteri dock’u üzerinde kalmalı',
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });

  testWidgets('live macOS QA — Screen 23 row actions menu', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('request_center_actions_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        requestCenterSnapshotProvider
            .overrideWith((ref) => AsyncValue.data(_qaSnapshot())),
      ],
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Aç'), findsOneWidget);
    expect(find.text('Detay'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '03_actions.png');
  });

  testWidgets('live macOS QA — Screen 23 partial/empty coverage',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('request_center_partial_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        requestCenterSnapshotProvider
            .overrideWith((ref) => AsyncValue.data(_qaSnapshot())),
      ],
    );

    // Dürüst kısmi kapsam: "Kayıtlı talepler henüz sunucuda tutulmuyor" şeridi.
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.textContaining('uydurma talep gösterilmez'),
      320,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('uydurma talep gösterilmez'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '04_empty_or_partial_state.png');
  });
}
