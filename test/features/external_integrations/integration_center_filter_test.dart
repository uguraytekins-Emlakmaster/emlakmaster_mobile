import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_capability.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_ui_state.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_ui_capabilities.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/utils/integration_center_filter.dart';
import 'package:flutter_test/flutter_test.dart';

IntegrationPlatform _row({
  required String name,
  required PlatformConnectionTruthKind truth,
  bool canSync = false,
  IntegrationSupportLevel supportLevel = IntegrationSupportLevel.tier2UserControlled,
}) {
  return IntegrationPlatform(
    id: IntegrationPlatformId.sahibinden,
    name: name,
    logoLabel: 'S',
    supportLevel: supportLevel,
    capabilities: PlatformUiCapabilities(
      canImportListings: true,
      canUpdatePrice: false,
      canManageMessages: false,
      canSync: canSync,
    ),
    connectionState: PlatformConnectionUiState.disconnected,
    truthKind: truth,
  );
}

void main() {
  group('computeIntegrationCenterSummary', () {
    test('counts real status buckets', () {
      final rows = [
        _row(name: 'Live', truth: PlatformConnectionTruthKind.liveConnected, canSync: true),
        _row(name: 'Setup', truth: PlatformConnectionTruthKind.setupIncomplete),
        _row(name: 'Preview', truth: PlatformConnectionTruthKind.mockDemo, canSync: true),
      ];
      final summary = computeIntegrationCenterSummary(rows, canManage: false);
      expect(summary.connectedAccounts, 1);
      expect(summary.setupRequired, 1);
      expect(summary.previewOnly, 1);
      expect(summary.adminRequired, 3);
      expect(summary.syncSupported, 2);
    });
  });

  group('matchesIntegrationCenterFilter', () {
    final live = _row(
      name: 'Sahibinden',
      truth: PlatformConnectionTruthKind.liveConnected,
      canSync: true,
      supportLevel: IntegrationSupportLevel.tier1Official,
    );
    final setup = _row(
      name: 'Hepsiemlak',
      truth: PlatformConnectionTruthKind.setupIncomplete,
    );
    final preview = _row(
      name: 'Emlakjet',
      truth: PlatformConnectionTruthKind.experimentalNotLive,
    );

    test('search matches platform and provider labels', () {
      expect(
        matchesIntegrationCenterFilter(live, IntegrationCenterFilter.all, 'sahibinden',
            canManage: true),
        isTrue,
      );
      expect(
        matchesIntegrationCenterFilter(live, IntegrationCenterFilter.all, 'resmi',
            canManage: true),
        isTrue,
      );
      expect(
        matchesIntegrationCenterFilter(live, IntegrationCenterFilter.all, 'olmayan',
            canManage: true),
        isFalse,
      );
    });

    test('chips evaluate with honest rules', () {
      expect(
        matchesIntegrationCenterFilter(live, IntegrationCenterFilter.connected, '',
            canManage: true),
        isTrue,
      );
      expect(
        matchesIntegrationCenterFilter(setup, IntegrationCenterFilter.setup, '',
            canManage: true),
        isTrue,
      );
      expect(
        matchesIntegrationCenterFilter(preview, IntegrationCenterFilter.preview, '',
            canManage: true),
        isTrue,
      );
      expect(
        matchesIntegrationCenterFilter(live, IntegrationCenterFilter.sync, '',
            canManage: true),
        isTrue,
      );
      expect(
        matchesIntegrationCenterFilter(live, IntegrationCenterFilter.admin, '',
            canManage: false),
        isTrue,
      );
    });
  });
}
