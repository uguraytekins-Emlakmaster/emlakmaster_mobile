// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/providers/baglantilar_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_command_surface.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_row.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen18_connections/live_qa';
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

BaglantiRowViewModel _row({
  required IntegrationPlatformId id,
  required String name,
  required String provider,
  required String detail,
  required String status,
  required BaglantiTone tone,
  required List<String> pills,
  bool needsAdmin = false,
  bool isConnected = false,
  bool isReady = false,
  bool needsSetup = false,
  bool isPreview = false,
  bool supportsSync = false,
  bool needsAction = false,
  bool canConnect = false,
  bool canConfigure = true,
  bool canImport = true,
  bool canRetry = true,
}) {
  return BaglantiRowViewModel(
    platformId: id,
    platformName: name,
    providerLine: provider,
    detailLine: detail,
    statusLabel: status,
    tone: tone,
    capabilityPills: pills,
    needsAdmin: needsAdmin,
    searchText: name.toLowerCase(),
    isConnected: isConnected,
    isReady: isReady,
    needsSetup: needsSetup,
    isPreview: isPreview,
    supportsSync: supportsSync,
    needsAction: needsAction,
    canConnect: canConnect,
    canConfigure: canConfigure,
    canImport: canImport,
    canRetry: canRetry,
  );
}

BaglantilarSnapshot _qaSnapshot() {
  return BaglantilarSnapshot(
    rows: [
      _row(
        id: IntegrationPlatformId.emlakjet,
        name: 'Emlakjet',
        provider: 'Deneysel',
        detail: 'Kurulum hatası · doğrulama gerekli',
        status: 'Hata',
        tone: BaglantiTone.danger,
        pills: const ['İçe aktarma'],
        needsAction: true,
        canConnect: true,
      ),
      _row(
        id: IntegrationPlatformId.sahibinden,
        name: 'Sahibinden.com',
        provider: 'Resmi sağlayıcı',
        detail: 'Demir Emlak · canlı bağlantı aktif',
        status: 'Bağlı (canlı)',
        tone: BaglantiTone.success,
        pills: const ['İçe aktarma', 'Senkron', 'Fiyat', 'Mesaj'],
        isConnected: true,
        isReady: true,
        supportsSync: true,
      ),
      _row(
        id: IntegrationPlatformId.hepsiemlak,
        name: 'Hepsiemlak',
        provider: 'Kullanıcı kontrollü',
        detail: 'Toplu içe aktarma hazır (dosya)',
        status: 'İçe aktarmaya hazır',
        tone: BaglantiTone.success,
        pills: const ['İçe aktarma', 'Senkron'],
        isReady: true,
        supportsSync: true,
      ),
      _row(
        id: IntegrationPlatformId.sahibinden,
        name: 'Önizleme Kanalı',
        provider: 'Deneysel',
        detail: 'Önizleme akışı · canlı entegrasyon değil',
        status: 'Önizleme',
        tone: BaglantiTone.info,
        pills: const ['İçe aktarma'],
        isPreview: true,
        needsAdmin: false,
      ),
    ],
    summary: const BaglantilarSummary(
      connected: 1,
      ready: 2,
      setupRequired: 0,
      previewOnly: 1,
      adminRequired: 0,
      syncSupported: 2,
      intervention: 1,
      total: 4,
    ),
    coverageNote:
        'Durumlar yalnızca gerçek platform kurulum kayıtlarından türetilir. '
        'Canlı OAuth/otomatik senkron yalnızca doğrulandığında “Bağlı” sayılır; '
        'önizleme kartları yalnızca arayüz örneğidir.',
    officeGrounded: true,
    isEmpty: false,
  );
}

const _emptySnapshot = BaglantilarSnapshot(
  rows: [],
  summary: BaglantilarSummary.empty,
  coverageNote:
      'Durumlar yalnızca gerçek platform kurulum kayıtlarından türetilir.',
  officeGrounded: false,
  isEmpty: true,
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

Widget _surfaceWithDock() {
  return const PremiumShellBackdrop(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: BaglantilarCommandSurface(),
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

List<Override> _populated() => [
      canManagePlatformIntegrationsProvider.overrideWithValue(true),
      baglantilarSnapshotProvider
          .overrideWithValue(AsyncValue.data(_qaSnapshot())),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealFont();
  });

  testWidgets('live macOS QA — Screen 18 header/summary/filters',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('baglanti_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _surfaceWithDock(),
      overrides: _populated(),
    );

    expect(find.text('Bağlantılar'), findsWidgets);
    expect(
      find.text('Platform durumu ve ofis entegrasyon kontrolü'),
      findsOneWidget,
    );
    expect(find.textContaining('Canlı OAuth'), findsWidgets);
    expect(find.text('Bağlı'), findsWidgets);
    expect(find.text('Hazır'), findsWidgets);
    expect(find.text('Kurulum sihirbazı'), findsWidgets);
    expect(find.text('Tümü'), findsWidgets);
    expect(find.textContaining('MÜDAHALE GEREKEN'), findsOneWidget);
    expect(find.text('Emlakjet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_summary_filters_live.png');

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Sahibinden.com'),
      400,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sahibinden.com'), findsOneWidget);
    expect(find.textContaining('TÜM BAĞLANTILAR'), findsOneWidget);
    await _savePng(tester, key, '02_connection_rows_live.png');

    await tester.scrollUntilVisible(
      find.text('Önizleme Kanalı'),
      400,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    final lastRow = find.text('Önizleme Kanalı');
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

  testWidgets('live macOS QA — Screen 18 row actions menu', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('baglanti_actions_live');
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
                BaglantilarRow(
                  viewModel: _row(
                    id: IntegrationPlatformId.hepsiemlak,
                    name: 'Hepsiemlak',
                    provider: 'Kullanıcı kontrollü',
                    detail: 'Kurulum tamamlanmadı · temel bilgiler eksik',
                    status: 'Kurulum gerekli',
                    tone: BaglantiTone.warning,
                    pills: const ['İçe aktarma', 'Senkron'],
                    needsSetup: true,
                    supportsSync: true,
                    canConnect: true,
                  ),
                  onTap: () {},
                  onDetail: () {},
                  onConnect: () {},
                  onConfigure: () {},
                  onImport: () {},
                  onRetry: () {},
                  onOfficeAdmin: () {},
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
    expect(find.text('Bağlan'), findsOneWidget);
    expect(find.text('Yapılandır'), findsOneWidget);
    expect(find.text('İçe aktar'), findsOneWidget);
    expect(find.text('Ofis Masasına git'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '03_actions_live.png');
  });

  testWidgets('live macOS QA — Screen 18 empty/partial state', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('baglanti_empty_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _surfaceWithDock(),
      overrides: [
        canManagePlatformIntegrationsProvider.overrideWithValue(true),
        baglantilarSnapshotProvider
            .overrideWithValue(const AsyncValue.data(_emptySnapshot)),
      ],
    );

    expect(find.textContaining('Platform kaydı bulunamadı'), findsOneWidget);
    expect(find.text('Kurulum sihirbazı'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '04_empty_or_partial_live.png');
  });
}
