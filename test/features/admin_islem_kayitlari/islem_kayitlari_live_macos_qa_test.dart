import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/providers/islem_kayitlari_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_command_surface.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen15_audit/live_qa';
const _macSize = Size(1280, 800);
const _phoneSize = Size(430, 932);

IslemKayitlariPageSnapshot _qaSnapshot() {
  final now = DateTime(2026, 5, 27, 14, 30);
  return IslemKayitlariPageSnapshot(
    rows: [
      IslemKayitlariRowViewModel(
        id: 'invite:i1',
        title: 'Davet oluşturuldu',
        actorLine: 'Ayşe Yılmaz',
        targetLine: 'zeynep@emlakmaster.com',
        detailLine: 'Rol: Danışman · Ekip ataması var',
        timestampLabel: '45 dk önce',
        occurredAt: now.subtract(const Duration(minutes: 45)),
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
        id: 'audit:1',
        title: 'Yetki değişimi — danışman rolü',
        actorLine: 'Broker Owner',
        targetLine: 'user · Burak Demir',
        detailLine: 'role: agent → team_lead',
        timestampLabel: '2 sa 15 dk önce',
        occurredAt: now.subtract(const Duration(hours: 2, minutes: 15)),
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
        id: 'audit:2',
        title: 'Ekip yöneticisi ataması değiştirildi',
        actorLine: 'Genel Müdür',
        targetLine: 'Ekip · Alpha Operasyon',
        detailLine: 'team.managerId güncellendi',
        timestampLabel: '6 sa önce',
        occurredAt: now.subtract(const Duration(hours: 6)),
        severity: IslemKayitlariSeverity.warning,
        category: IslemKayitlariCategory.team,
        source: IslemKayitlariEventSource.auditLog,
        sourceLabel: 'Audit kaydı',
        categoryLabel: 'Ekip',
        suggestedFilter: IslemKayitlariFilter.team,
        consultantId: null,
        teamId: 't1',
        hasPartialMetadata: false,
      ),
      for (var i = 3; i <= 14; i++)
        IslemKayitlariRowViewModel(
          id: 'audit:$i',
          title: 'Danışman profili güncellendi — Kayıt $i',
          actorLine: 'Ofis Yöneticisi',
          targetLine: 'agent · Danışman $i',
          detailLine: 'consultant.profile.update',
          timestampLabel: '${i + 6} sa önce',
          occurredAt: now.subtract(Duration(hours: i + 6)),
          severity: IslemKayitlariSeverity.info,
          category: IslemKayitlariCategory.consultant,
          source: IslemKayitlariEventSource.auditLog,
          sourceLabel: 'Audit kaydı',
          categoryLabel: 'Danışman',
          suggestedFilter: IslemKayitlariFilter.consultant,
          consultantId: 'u$i',
          teamId: 't1',
          hasPartialMetadata: i.isOdd,
        ),
    ],
    strip: const IslemKayitlariHealthStrip(
      last24hCount: 5,
      criticalCount: 1,
      teamChangeCount: 2,
      consultantActionCount: 10,
      inviteCount: 1,
      warningCount: 2,
      totalEvents: 14,
      auditLogCount: 13,
      hasPartialCoverage: true,
    ),
    isEmpty: false,
    hasAuditLogs: true,
    hasInvites: true,
    coverageNote:
        'Kaynaklar: audit_logs ve davet kayıtları. Tüm admin işlemleri henüz loglanmıyor olabilir.',
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

Widget _auditWithDockHarness() {
  return PremiumShellBackdrop(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: const SafeArea(
        bottom: false,
        child: IslemKayitlariCommandSurface(),
      ),
      bottomNavigationBar: PremiumBottomNavDock(
        items: const [
          AdaptiveNavItem(Icons.dashboard_rounded, ProductLabels.managerHome),
          AdaptiveNavItem(Icons.military_tech_rounded, ProductLabels.warRoom),
          AdaptiveNavItem(Icons.call_rounded, ProductLabels.callCenter),
          AdaptiveNavItem(Icons.analytics_rounded, ProductLabels.reports),
        ],
        selectedIndex: 3,
        onTap: (_) {},
      ),
    ),
  );
}

final _shellKey = GlobalKey<AdaptiveShellScaffoldState>();

Widget _realAdminShellHarness() {
  return AdaptiveShellScaffold(
    key: _shellKey,
    title: ProductLabels.managerWorkspace,
    navItems: const [
      AdaptiveNavItem(Icons.dashboard_rounded, ProductLabels.managerHome),
      AdaptiveNavItem(Icons.military_tech_rounded, ProductLabels.warRoom),
      AdaptiveNavItem(Icons.call_rounded, ProductLabels.callCenter),
      AdaptiveNavItem(Icons.analytics_rounded, ProductLabels.reports),
    ],
    pages: const [
      SizedBox.shrink(),
      SizedBox.shrink(),
      SizedBox.shrink(),
      SafeArea(
        bottom: false,
        child: IslemKayitlariCommandSurface(),
      ),
    ],
  );
}

List<Override> _qaOverrides() => [
      islemKayitlariSnapshotProvider.overrideWith(
        (ref) => AsyncValue.data(_qaSnapshot()),
      ),
      displayRoleOrNullProvider.overrideWith((ref) => AppRole.brokerOwner),
    ];

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
  Size size = _macSize,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _qaOverrides(),
      child: MaterialApp(
        theme: AppTheme.dark(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizationsDelegate(),
        ],
        locale: const Locale('tr'),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: RepaintBoundary(
            key: captureKey,
            child: child,
          ),
        ),
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

  testWidgets('live macOS QA — Screen 15 İşlem Kayıtları', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('audit_live_qa');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _auditWithDockHarness(),
    );

    // A — Real readable text (header, coverage, strip, ≥2 rows)
    expect(find.text('İşlem Kayıtları'), findsOneWidget);
    expect(find.text('Operasyon geçmişi ve değişiklik takibi'), findsOneWidget);
    expect(
      find.textContaining('audit_logs ve davet kayıtları'),
      findsOneWidget,
    );
    expect(find.text('Son 24s'), findsWidgets);
    expect(find.text('Kritik'), findsWidgets);
    expect(find.text('Davet oluşturuldu'), findsOneWidget);
    expect(find.text('Yetki değişimi — danışman rolü'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '06_live_text_readability.png');

    // B — Real dock coexistence (last row above dock)
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Danışman profili güncellendi — Kayıt 14'),
      500,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    final lastRowTitle = find.text('Danışman profili güncellendi — Kayıt 14');
    expect(lastRowTitle, findsOneWidget);

    final dock = find.byType(PremiumBottomNavDock);
    expect(dock, findsOneWidget);

    final rowBottom = _globalBottom(tester, lastRowTitle);
    final dockTop = _globalTop(tester, dock);
    expect(
      rowBottom,
      lessThan(dockTop - 8),
      reason: 'Last audit row must sit above the admin dock',
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '07_live_dock_coexistence.png');
  });

  testWidgets('live macOS QA — Screen 15 real admin shell dock bottom', (
    tester,
  ) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('audit_shell_dock');
    await _pumpHarness(
      tester,
      captureKey: key,
      child: _realAdminShellHarness(),
      size: _phoneSize,
    );

    _shellKey.currentState?.jumpToTab(3);
    await tester.pumpAndSettle();

    expect(find.text('İşlem Kayıtları'), findsOneWidget);
    expect(find.byType(PremiumBottomNavDock), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Danışman profili güncellendi — Kayıt 14'),
      500,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    final lastRowTitle = find.text('Danışman profili güncellendi — Kayıt 14');
    expect(lastRowTitle, findsOneWidget);

    final dock = find.byType(PremiumBottomNavDock);
    final rowBottom = _globalBottom(tester, lastRowTitle);
    final dockTop = _globalTop(tester, dock);
    expect(
      rowBottom,
      lessThan(dockTop - 8),
      reason: 'Last audit row must sit above the real admin shell dock',
    );
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '08_live_shell_dock_bottom.png');
  });
}
