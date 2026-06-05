import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_capability.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_ui_state.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_ui_capabilities.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/models/integration_center_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/utils/integration_center_filter.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/consultant_integrations_chrome.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_center_platform_card.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_center_row_actions.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen8_integrations';
const _phoneSize = Size(390, 844);
const _pixelRatio = 3.0;

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(800));
  });
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
  Size size = _phoneSize,
  double? height,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: Material(
          color: const Color(0xFF0A0E1A),
          child: Center(
            child: SizedBox(
              width: size.width,
              height: height ?? size.height,
              child: RepaintBoundary(
                key: captureKey,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

IntegrationPlatform _row({
  required String name,
  required String letter,
  required PlatformConnectionTruthKind truth,
  required bool sync,
}) {
  return IntegrationPlatform(
    id: IntegrationPlatformId.sahibinden,
    name: name,
    logoLabel: letter,
    supportLevel: IntegrationSupportLevel.tier2UserControlled,
    capabilities: PlatformUiCapabilities(
      canImportListings: true,
      canUpdatePrice: false,
      canManageMessages: false,
      canSync: sync,
    ),
    connectionState: truth == PlatformConnectionTruthKind.liveConnected
        ? PlatformConnectionUiState.connected
        : PlatformConnectionUiState.needsAttention,
    truthKind: truth,
    connectedAccountLabel: 'Örnek sağlayıcı',
  );
}

Widget _platformCard(IntegrationPlatform row, {bool canManage = true}) {
  final snapshot =
      IntegrationCenterRowSnapshot.fromPlatform(row, canManage: canManage);
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: IntegrationCenterPlatformCard(
      platform: row,
      snapshot: snapshot,
      onTap: () {},
      onConnect: () {},
      onConfigure: () {},
      onOpen: () {},
      onRetry: () {},
      onLearnMore: () {},
    ),
  );
}

Widget _consultantShellDock({required Widget body}) {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0E1A),
    body: body,
    bottomNavigationBar: PremiumBottomNavDock(
      items: const [
        AdaptiveNavItem(Icons.space_dashboard_rounded, ProductLabels.consultantHome),
        AdaptiveNavItem(Icons.call_rounded, ProductLabels.myCalls),
        AdaptiveNavItem(Icons.people_rounded, ProductLabels.myCustomers),
        AdaptiveNavItem(Icons.task_alt_rounded, ProductLabels.myTasks),
        AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
      ],
      selectedIndex: 4,
      onTap: (_) {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 — header health filters proof', (tester) async {
    const key = Key('proof_integrations_header');
    const summary = IntegrationCenterSummary(
      connectedAccounts: 1,
      setupRequired: 2,
      previewOnly: 1,
      adminRequired: 0,
      syncSupported: 2,
    );

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumIntegrationsPageHeader(
            title: 'Entegrasyon Merkezi',
            subtitle: 'harici bağlantılar ve veri akışı',
          ),
          const PremiumIntegrationsSummaryStrip(summary: summary),
          PremiumIntegrationsSearchRow(
            controller: TextEditingController(),
            hintText: 'Platform, durum veya sağlayıcı ara',
          ),
          PremiumIntegrationsFilterStrip(
            selected: IntegrationCenterFilter.setup,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '01_header_health_filters.png');
    expect(find.byKey(const Key('integration_filter_strip_scroll')), findsOneWidget);
    expect(find.text('Entegrasyon Merkezi'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('02 — platform rows proof', (tester) async {
    const key = Key('proof_integrations_rows');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 560,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _platformCard(
              _row(
                name: 'Sahibinden.com',
                letter: 'S',
                truth: PlatformConnectionTruthKind.setupIncomplete,
                sync: true,
              ),
            ),
            _platformCard(
              _row(
                name: 'Hepsiemlak',
                letter: 'H',
                truth: PlatformConnectionTruthKind.experimentalNotLive,
                sync: true,
              ),
            ),
            _platformCard(
              _row(
                name: 'Emlakjet',
                letter: 'E',
                truth: PlatformConnectionTruthKind.liveNotEnabled,
                sync: false,
              ),
              canManage: false,
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '02_platform_rows.png');
    expect(find.text('Sahibinden.com'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('03 — actions proof', (tester) async {
    const key = Key('proof_integrations_actions');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 140,
      child: const Center(
        child: IntegrationCenterRowActions(
          onConnect: null,
          onConfigure: null,
          onOpen: null,
          onRetry: null,
          onLearnMore: null,
          canConnect: true,
          canConfigure: true,
          canOpen: true,
          canRetry: true,
        ),
      ),
    );
    await _savePng(tester, key, '03_actions.png');
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('04 — empty or preview proof', (tester) async {
    const key = Key('proof_integrations_empty');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 580,
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumIntegrationsPageHeader(
              title: 'Entegrasyon Merkezi',
              subtitle: 'harici bağlantılar ve veri akışı',
            ),
            PremiumIntegrationsSummaryStrip(summary: IntegrationCenterSummary.empty),
            EmptyState(
              premiumVisual: true,
              grouped: true,
              icon: Icons.hub_outlined,
              title: 'Bağlantı altyapısı hazırlanıyor',
              subtitle: 'Kanal bağlantısı gerekli olduğunda bu merkezden yönetilecektir.',
              actionLabel: 'Daha fazla bilgi',
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '04_empty_or_preview.png');
    expect(find.text('Bağlantı altyapısı hazırlanıyor'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('05 — bottom nav safe area proof', (tester) async {
    const key = Key('proof_integrations_dock');
    await _pumpFrame(
      tester,
      captureKey: key,
      size: _phoneSize,
      height: _phoneSize.height,
      child: _consultantShellDock(
        body: Column(
          children: [
            const PremiumIntegrationsPageHeader(
              title: 'Entegrasyon Merkezi',
              subtitle: 'harici bağlantılar ve veri akışı',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  _platformCard(
                    _row(
                      name: 'Son satır — dock altında görünür',
                      letter: 'S',
                      truth: PlatformConnectionTruthKind.setupIncomplete,
                      sync: true,
                    ),
                  ),
                  _platformCard(
                    _row(
                      name: 'İkinci satır',
                      letter: 'H',
                      truth: PlatformConnectionTruthKind.experimentalNotLive,
                      sync: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
    expect(find.text('Son satır — dock altında görünür'), findsOneWidget);
    expect(find.byType(PremiumBottomNavDock), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });
}
