// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/providers/account_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_row.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen24_client_profile/live_qa';
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

AccountSnapshot _qaSnapshot() => computeAccountSnapshot(
      signedIn: true,
      email: 'ada.yilmaz@example.com',
      displayName: 'Ada Yılmaz',
      phone: '+90 555 111 22 33',
      memberSinceLabel: '15.01.2024',
      emailVerified: true,
      appVersion: '1.0.0',
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
        child: AccountSurface(),
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
        selectedIndex: 4,
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

  testWidgets('live macOS QA — Screen 24 header/summary/sections + dock',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('account_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        accountSnapshotProvider
            .overrideWithValue(AsyncValue.data(_qaSnapshot())),
      ],
    );

    expect(find.text('Hesabım'), findsWidgets);
    expect(find.textContaining('Ada Yılmaz'), findsWidgets);
    expect(find.textContaining('sunucuda'), findsWidgets);
    expect(find.text('Tümü'), findsWidgets);
    expect(find.text('Kısmi'), findsWidgets);
    expect(find.text('E-posta'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_summary_sections.png');

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Çıkış yap'),
      280,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Çıkış yap'), findsOneWidget);
    await _savePng(tester, key, '02_profile_rows.png');

    // Dürüst kapsam notu (Kayıtlı tercihler) dock üzerinde kalmalı.
    await tester.scrollUntilVisible(
      find.textContaining('uydurma bilgi gösterilmez'),
      280,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final lastNote = find.textContaining('uydurma bilgi gösterilmez');
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

  testWidgets('live macOS QA — Screen 24 satır detay sheet', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('account_actions_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        accountSnapshotProvider
            .overrideWithValue(AsyncValue.data(_qaSnapshot())),
      ],
    );

    await tester.tap(find.byType(AccountRow).first);
    await tester.pumpAndSettle();
    // Detay satırları RichText (TextSpan) ile çizilir → findRichText gerekir.
    expect(find.textContaining('Değer', findRichText: true), findsWidgets);
    expect(find.textContaining('Bağlam', findRichText: true), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '03_actions.png');
  });

  testWidgets('live macOS QA — Screen 24 oturumsuz dürüst durum',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('account_partial_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        accountSnapshotProvider.overrideWithValue(
          AsyncValue.data(
            computeAccountSnapshot(
              signedIn: false,
              emailVerified: false,
              appVersion: '1.0.0',
            ),
          ),
        ),
      ],
    );

    expect(find.text('Giriş yapılmamış'), findsWidgets);
    expect(find.text('Çıkış yap'), findsNothing);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '04_empty_or_partial_state.png');
  });
}
