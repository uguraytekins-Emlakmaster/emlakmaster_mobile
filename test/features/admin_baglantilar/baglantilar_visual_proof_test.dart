// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/admin_baglantilar_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_row.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_skeleton.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen18_connections';
const _phone390 = Size(390, 844);

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(800));
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Key key,
  required Widget child,
  Size size = _phone390,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: RepaintBoundary(
          key: key,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _summary = BaglantilarSummary(
  connected: 1,
  ready: 2,
  setupRequired: 1,
  previewOnly: 2,
  adminRequired: 0,
  syncSupported: 2,
  intervention: 1,
  total: 5,
);

const _connected = BaglantiRowViewModel(
  platformId: IntegrationPlatformId.sahibinden,
  platformName: 'Sahibinden.com',
  providerLine: 'Resmi sağlayıcı',
  detailLine: 'Demir Emlak · canlı bağlantı aktif',
  statusLabel: 'Bağlı (canlı)',
  tone: BaglantiTone.success,
  capabilityPills: ['İçe aktarma', 'Senkron', 'Fiyat', 'Mesaj'],
  needsAdmin: false,
  searchText: 'sahibinden',
  isConnected: true,
  isReady: true,
  needsSetup: false,
  isPreview: false,
  supportsSync: true,
  needsAction: false,
  canConnect: false,
  canConfigure: true,
  canImport: true,
  canRetry: true,
);

const _intervention = BaglantiRowViewModel(
  platformId: IntegrationPlatformId.emlakjet,
  platformName: 'Emlakjet',
  providerLine: 'Deneysel',
  detailLine: 'Kurulum hatası · doğrulama gerekli',
  statusLabel: 'Hata',
  tone: BaglantiTone.danger,
  capabilityPills: ['İçe aktarma'],
  needsAdmin: false,
  searchText: 'emlakjet',
  isConnected: false,
  isReady: false,
  needsSetup: false,
  isPreview: false,
  supportsSync: false,
  needsAction: true,
  canConnect: true,
  canConfigure: true,
  canImport: true,
  canRetry: true,
);

const _setup = BaglantiRowViewModel(
  platformId: IntegrationPlatformId.hepsiemlak,
  platformName: 'Hepsiemlak',
  providerLine: 'Kullanıcı kontrollü',
  detailLine: 'Kurulum tamamlanmadı · temel bilgiler eksik',
  statusLabel: 'Kurulum gerekli',
  tone: BaglantiTone.warning,
  capabilityPills: ['İçe aktarma', 'Senkron'],
  needsAdmin: false,
  searchText: 'hepsiemlak',
  isConnected: false,
  isReady: false,
  needsSetup: true,
  isPreview: false,
  supportsSync: true,
  needsAction: false,
  canConnect: true,
  canConfigure: true,
  canImport: true,
  canRetry: true,
);

const _preview = BaglantiRowViewModel(
  platformId: IntegrationPlatformId.sahibinden,
  platformName: 'Önizleme Kanalı',
  providerLine: 'Deneysel',
  detailLine: 'Önizleme akışı · canlı entegrasyon değil',
  statusLabel: 'Önizleme',
  tone: BaglantiTone.info,
  capabilityPills: ['İçe aktarma'],
  needsAdmin: true,
  searchText: 'önizleme',
  isConnected: false,
  isReady: false,
  needsSetup: false,
  isPreview: true,
  supportsSync: false,
  needsAction: false,
  canConnect: false,
  canConfigure: false,
  canImport: true,
  canRetry: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header summary filters proof', (tester) async {
    const key = Key('proof_header');
    await _pump(
      tester,
      key: key,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const PremiumBaglantilarHeader(
              coverageNote:
                  'Durumlar yalnızca gerçek platform kurulum kayıtlarından türetilir. '
                  'Canlı OAuth/otomatik senkron yalnızca doğrulandığında “Bağlı” sayılır.',
            ),
            const BaglantilarSummaryStripView(summary: _summary),
            BaglantilarQuickRoutes(
              onSetupWizard: () {},
              onImport: () {},
              onMyListings: () {},
              onOfficeAdmin: () {},
              onAudit: () {},
            ),
            BaglantilarCompactSearch(
              hintText: 'Platform, durum veya sağlayıcı ara',
              onChanged: (_) {},
            ),
            BaglantilarFilterStrip(
              selected: BaglantilarFilter.all,
              onSelected: (_) {},
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '01_header_summary_filters.png');
  });

  testWidgets('02 connection rows proof', (tester) async {
    const key = Key('proof_rows');
    await _pump(
      tester,
      key: key,
      child: ListView(
        children: [
          const BaglantilarSectionHeader(
            title: 'Müdahale gereken',
            note: 'Kurulum kaydı dikkat isteyen platformlar.',
          ),
          BaglantilarRow(
            viewModel: _intervention,
            onTap: () {},
            onDetail: () {},
            onConnect: () {},
            onConfigure: () {},
            onRetry: () {},
            onOfficeAdmin: () {},
          ),
          const BaglantilarSectionHeader(title: 'Tüm bağlantılar', count: 3),
          BaglantilarRow(
            viewModel: _connected,
            onTap: () {},
            onDetail: () {},
            onOpen: () {},
            onConfigure: () {},
            onImport: () {},
            onOfficeAdmin: () {},
          ),
          BaglantilarRow(
            viewModel: _setup,
            onTap: () {},
            onDetail: () {},
            onConnect: () {},
            onConfigure: () {},
            onImport: () {},
            onOfficeAdmin: () {},
          ),
          BaglantilarRow(
            viewModel: _preview,
            onTap: () {},
            onDetail: () {},
            onOpen: () {},
            onImport: () {},
            onOfficeAdmin: () {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '02_connection_rows.png');
  });

  testWidgets('03 actions proof', (tester) async {
    const key = Key('proof_actions');
    await _pump(
      tester,
      key: key,
      child: BaglantilarRow(
        viewModel: _setup,
        onTap: () {},
        onDetail: () {},
        onConnect: () {},
        onConfigure: () {},
        onImport: () {},
        onRetry: () {},
        onOfficeAdmin: () {},
      ),
    );
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await _savePng(tester, key, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    const key = Key('proof_empty');
    await _pump(
      tester,
      key: key,
      child: const BaglantilarEmptyState(
        title: 'Platform kaydı bulunamadı',
        message:
            'Entegrasyon kataloğu hazır olduğunda platformlar burada görünecek.',
        actionLabel: 'Kurulum sihirbazı',
        onAction: null,
      ),
    );
    await _savePng(tester, key, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    const key = Key('proof_bottom');
    await _pump(
      tester,
      key: key,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                BaglantilarRow(
                  viewModel: _intervention,
                  onTap: () {},
                  onDetail: () {},
                ),
                BaglantilarRow(
                  viewModel: _connected,
                  onTap: () {},
                  onDetail: () {},
                ),
                BaglantilarRow(
                  viewModel: _setup,
                  onTap: () {},
                  onDetail: () {},
                ),
                BaglantilarRow(
                  viewModel: _preview,
                  onTap: () {},
                  onDetail: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AdminBaglantilarTokens.bottomReserve),
        ],
      ),
    );
    await _savePng(tester, key, '05_bottom_safe_area.png');
  });

  testWidgets('loading skeleton renders', (tester) async {
    await _pump(
      tester,
      key: const Key('skel'),
      child: const BaglantilarLoadingSkeleton(),
    );
    expect(find.byType(BaglantilarLoadingSkeleton), findsOneWidget);
  });
}
