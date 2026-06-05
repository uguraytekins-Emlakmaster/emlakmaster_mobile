// ignore_for_file: avoid_redundant_argument_values

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/admin_baglantilar_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_row.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Profile {
  const _Profile(this.name, this.size);
  final String name;
  final Size size;
}

const _profiles = [
  _Profile('iPhone SE', Size(320, 568)),
  _Profile('iPhone 14/15', Size(390, 844)),
  _Profile('Android compact', Size(360, 780)),
  _Profile('Android normal', Size(412, 915)),
  _Profile('tablet', Size(768, 1024)),
  _Profile('macOS window', Size(900, 700)),
];

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

const _longRow = BaglantiRowViewModel(
  platformId: IntegrationPlatformId.sahibinden,
  platformName: 'Çok Uzun Platform Adı Buraya Gelecek Sahibinden Premium Resmi',
  providerLine: 'Resmi sağlayıcı',
  detailLine:
      'cok.uzun.hesap.adresi.buraya.gelecek@emlakmastergayrimenkul.com · canlı bağlantı aktif değil',
  statusLabel: 'Kurulum gerekli',
  tone: BaglantiTone.warning,
  capabilityPills: ['İçe aktarma', 'Senkron', 'Fiyat', 'Mesaj'],
  needsAdmin: true,
  searchText: 'uzun',
  isConnected: false,
  isReady: false,
  needsSetup: true,
  isPreview: false,
  supportsSync: true,
  needsAction: true,
  canConnect: true,
  canConfigure: true,
  canImport: true,
  canRetry: true,
);

Future<void> _pumpChrome(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                BaglantilarCompactSearch(hintText: 'Ara', onChanged: (_) {}),
                BaglantilarFilterStrip(
                  selected: BaglantilarFilter.all,
                  onSelected: (_) {},
                ),
                const BaglantilarSectionHeader(
                  title: 'Müdahale gereken',
                  note: 'Kurulum kaydı dikkat isteyen platformlar.',
                ),
                BaglantilarRow(
                  viewModel: _longRow,
                  onTap: () {},
                  onDetail: () {},
                  onConnect: () {},
                  onConfigure: () {},
                  onImport: () {},
                  onRetry: () {},
                  onOfficeAdmin: () {},
                ),
                const BaglantilarSectionHeader(
                  title: 'Tüm bağlantılar',
                  count: 5,
                ),
                BaglantilarRow(
                  viewModel: _longRow,
                  onTap: () {},
                  onDetail: () {},
                  onConfigure: () {},
                  onOfficeAdmin: () {},
                ),
                const SizedBox(height: AdminBaglantilarTokens.bottomReserve),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final profile in _profiles) {
    testWidgets('Bağlantılar chrome zero overflow · ${profile.name}',
        (tester) async {
      await _pumpChrome(tester, profile.size);
      expect(tester.takeException(), isNull);
    });
  }
}
