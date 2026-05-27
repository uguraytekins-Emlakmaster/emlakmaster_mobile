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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size, double textScale})>[
  (name: 'iPhone SE', size: Size(320, 568), textScale: 1.0),
  (name: 'iPhone 14', size: Size(390, 844), textScale: 1.0),
  (name: 'iPhone 15 Pro', size: Size(393, 852), textScale: 1.15),
  (name: 'Android compact', size: Size(360, 640), textScale: 1.0),
  (name: 'Android normal', size: Size(412, 915), textScale: 1.0),
  (name: 'macOS windowed', size: Size(1280, 800), textScale: 1.0),
  (name: 'iPad tablet', size: Size(834, 1194), textScale: 1.0),
  (name: 'large tablet', size: Size(1024, 1366), textScale: 1.1),
];

IntegrationPlatform _sampleRow() => IntegrationPlatform(
      id: IntegrationPlatformId.sahibinden,
      name: 'Sahibinden.com',
      logoLabel: 'S',
      supportLevel: IntegrationSupportLevel.tier1Official,
      capabilities: const PlatformUiCapabilities(
        canImportListings: true,
        canUpdatePrice: true,
        canManageMessages: false,
        canSync: true,
      ),
      connectionState: PlatformConnectionUiState.needsAttention,
      truthKind: PlatformConnectionTruthKind.setupIncomplete,
      connectedAccountLabel: 'Örnek hesap',
    );

Future<void> _pumpChrome(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final row = _sampleRow();
  final snapshot = IntegrationCenterRowSnapshot.fromPlatform(row, canManage: true);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: EdgeInsets.only(bottom: size.height > 700 ? 34 : 0),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PremiumIntegrationsPageHeader(
                  title: 'Entegrasyon Merkezi',
                  subtitle: 'harici bağlantılar ve veri akışı',
                ),
                PremiumIntegrationsSummaryStrip(
                  summary: const IntegrationCenterSummary(
                    connectedAccounts: 1,
                    setupRequired: 2,
                    previewOnly: 1,
                    adminRequired: 0,
                    syncSupported: 2,
                  ),
                ),
                PremiumIntegrationsFilterStrip(
                  selected: IntegrationCenterFilter.all,
                  onSelected: (_) {},
                ),
                IntegrationCenterPlatformCard(
                  platform: row,
                  snapshot: snapshot,
                  onTap: () {},
                  onConnect: () {},
                  onConfigure: () {},
                  onOpen: () {},
                  onRetry: () {},
                  onLearnMore: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('Consultant Integrations overflow zero', () {
    for (final profile in _profiles) {
      testWidgets('chrome + dense row · ${profile.name}', (tester) async {
        await _pumpChrome(tester, profile.size, profile.textScale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
