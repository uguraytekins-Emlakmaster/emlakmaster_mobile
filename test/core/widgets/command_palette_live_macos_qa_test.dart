import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/widgets/command_palette.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen22_navigation/live_qa';
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

Future<void> _openPalette(
  WidgetTester tester, {
  required Key captureKey,
  required AppRole role,
}) async {
  tester.view.physicalSize = _phoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        displayRoleOrNullProvider.overrideWithValue(role),
      ],
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
        builder: (context, app) =>
            RepaintBoundary(key: captureKey, child: app),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CommandPalette.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealFont();
  });

  testWidgets('live macOS QA — admin komut paleti gerçek metin', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    const key = Key('palette_admin_live');
    await _openPalette(tester, captureKey: key, role: AppRole.brokerOwner);

    expect(find.text(ProductLabels.officeDesk), findsOneWidget);
    expect(find.text(ProductLabels.warRoom), findsOneWidget);
    expect(find.text(ProductLabels.callCenter), findsOneWidget);
    expect(find.text(ProductLabels.settings), findsOneWidget);
    // Müşteri sekmesi yok (dürüst omission).
    expect(find.text(ProductLabels.favorites), findsNothing);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_admin_routes_live.png');
  });

  testWidgets('live macOS QA — danışman kısayolları gerçek metin',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    const key = Key('palette_consultant_live');
    await _openPalette(tester, captureKey: key, role: AppRole.agent);

    expect(find.text(ProductLabels.myCustomers), findsOneWidget);
    expect(find.text(ProductLabels.myCalls), findsOneWidget);
    expect(find.text(ProductLabels.officeDesk), findsNothing);
    expect(find.text(ProductLabels.warRoom), findsNothing);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '02_consultant_shortcuts_live.png');
  });

  testWidgets('live macOS QA — danışman rol farkındalığı gerçek metin',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    const key = Key('palette_agent_live');
    await _openPalette(tester, captureKey: key, role: AppRole.agent);

    expect(find.text(ProductLabels.myCustomers), findsOneWidget);
    expect(find.text(ProductLabels.officeDesk), findsNothing);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '03_agent_role_live.png');
  });
}
