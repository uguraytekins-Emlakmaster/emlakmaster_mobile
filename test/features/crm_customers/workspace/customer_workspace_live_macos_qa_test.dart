// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_host.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/providers/customer_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_row.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen25_consultant_customers/live_qa';
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

CustomerWorkspaceSnapshot _qaSnapshot() {
  final now = DateTime(2024, 6, 15, 12);
  return computeCustomerWorkspaceSnapshot(
    [
      CustomerWorkspaceInput(
        id: 'qa1',
        name: 'Ada Yılmaz',
        phone: '+90 555 111 22 33',
        heatLevel: CustomerHeatLevel.hot,
        heatScore: 85,
        heatReason: 'Yüksek ilgi · acil takip',
        lastInteractionAt: now,
        createdAt: DateTime(2024, 6, 10),
        updatedAt: now,
        nextSuggestedAction: 'Tekrar ara',
        callablePhone: true,
        syncRisk: false,
        isDemo: false,
      ),
      CustomerWorkspaceInput(
        id: 'qa2',
        name: 'Mehmet Demir',
        phone: '+90 532 999 88 77',
        heatLevel: CustomerHeatLevel.warm,
        heatScore: 52,
        heatReason: 'Takip için uygun',
        lastInteractionAt: now.subtract(const Duration(days: 18)),
        createdAt: DateTime(2024, 1, 15),
        updatedAt: now.subtract(const Duration(days: 18)),
        callablePhone: true,
        syncRisk: false,
        isDemo: false,
      ),
    ],
    now: now,
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
        child: ShellTabBackHost(
          pageIndex: 3,
          child: CustomerWorkspaceSurface(),
        ),
      ),
      bottomNavigationBar: PremiumBottomNavDock(
        items: [
          AdaptiveNavItem(Icons.space_dashboard_rounded, ProductLabels.consultantHome),
          AdaptiveNavItem(Icons.call_rounded, ProductLabels.myCalls),
          AdaptiveNavItem(Icons.people_rounded, ProductLabels.myCustomers),
          AdaptiveNavItem(Icons.task_alt_rounded, ProductLabels.myTasks),
          AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
        ],
        selectedIndex: 2,
        onTap: _noop,
      ),
    ),
  );
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Key captureKey,
  required List<Override> overrides,
}) async {
  tester.view.physicalSize = _phoneSize;
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
            data: MediaQuery.of(context).copyWith(size: _phoneSize),
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

  testWidgets('live macOS QA — Screen 25 header/summary/filters + dock',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('customers_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        customerWorkspaceSnapshotProvider
            .overrideWithValue(AsyncValue.data(_qaSnapshot())),
      ],
    );

    expect(find.text('Müşterilerim'), findsWidgets);
    expect(find.textContaining('yapay zekâ'), findsWidgets);
    expect(find.text('Tümü'), findsWidgets);
    expect(find.text('Temas gerekli'), findsWidgets);
    expect(find.text('Ada Yılmaz'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '01_header_summary_filters.png');

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Mehmet Demir'),
      280,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await _savePng(tester, key, '02_customer_rows.png');

    // Dock çakışması — son satır (Mehmet Demir) dock üstünde kalmalı.
    final dock = find.byType(PremiumBottomNavDock);
    expect(dock, findsOneWidget);
    final lastRow = find.text('Mehmet Demir');
    expect(
      _globalBottom(tester, lastRow),
      lessThan(_globalTop(tester, dock)),
      reason: 'Son içerik danışman dock üzerinde kalmalı',
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });

  testWidgets('live macOS QA — Screen 25 satır aksiyon menüsü', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('customers_actions_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        customerWorkspaceSnapshotProvider
            .overrideWithValue(AsyncValue.data(_qaSnapshot())),
      ],
    );

    await tester.tap(find.byType(PopupMenuButton<CustomerRowMenu>).first);
    await tester.pumpAndSettle();
    expect(find.text('Ara'), findsWidgets);
    expect(find.text('Takibe ekle'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '03_actions.png');
  });

  testWidgets('live macOS QA — Screen 25 boş portföy dürüst durum',
      (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('customers_empty_live');
    await _pumpHarness(
      tester,
      captureKey: key,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        customerWorkspaceSnapshotProvider.overrideWithValue(
          AsyncValue.data(
            computeCustomerWorkspaceSnapshot([], now: DateTime(2024, 6, 15)),
          ),
        ),
      ],
    );

    expect(find.text('Müşteri portföyünü burada kur'), findsOneWidget);
    expect(find.textContaining('yapay zekâ'), findsWidgets);
    expect(find.text('Müşteri ekle'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '04_empty_or_partial_state.png');
  });
}
