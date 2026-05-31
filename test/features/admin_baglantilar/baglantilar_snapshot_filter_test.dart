// ignore_for_file: avoid_redundant_argument_values

import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_filter.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_capability.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_ui_state.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_lifecycle.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_ui_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

IntegrationPlatform _p({
  required String name,
  IntegrationPlatformId id = IntegrationPlatformId.sahibinden,
  required PlatformConnectionTruthKind truth,
  PlatformSetupLifecycleState? lifecycle,
  bool canImport = true,
  bool canSync = false,
  bool canPrice = false,
  bool canMessages = false,
  IntegrationSupportLevel support = IntegrationSupportLevel.tier1Official,
  String? account,
}) {
  return IntegrationPlatform(
    id: id,
    name: name,
    logoLabel: name.substring(0, 1),
    supportLevel: support,
    capabilities: PlatformUiCapabilities(
      canImportListings: canImport,
      canUpdatePrice: canPrice,
      canManageMessages: canMessages,
      canSync: canSync,
    ),
    connectionState: PlatformConnectionUiState.disconnected,
    truthKind: truth,
    connectedAccountLabel: account,
    setupLifecycle: lifecycle,
  );
}

List<IntegrationPlatform> _sample() => [
      _p(
        name: 'Alpha',
        truth: PlatformConnectionTruthKind.liveConnected,
        lifecycle: PlatformSetupLifecycleState.liveEnabled,
        canSync: true,
        account: 'alpha@office.com',
      ),
      _p(
        name: 'Beta',
        truth: PlatformConnectionTruthKind.experimentalNotLive,
        lifecycle: PlatformSetupLifecycleState.readyForImport,
      ),
      _p(
        name: 'Gamma',
        truth: PlatformConnectionTruthKind.setupIncomplete,
        lifecycle: PlatformSetupLifecycleState.error,
      ),
      _p(
        name: 'Delta',
        truth: PlatformConnectionTruthKind.setupIncomplete,
      ),
      _p(
        name: 'Epsilon',
        truth: PlatformConnectionTruthKind.mockDemo,
        canSync: true,
      ),
    ];

void main() {
  group('computeBaglantilarSnapshot', () {
    test('summary counts are derived only from real states', () {
      final s = computeBaglantilarSnapshot(
        platforms: _sample(),
        canManage: true,
        officeGrounded: true,
      );

      expect(s.summary.total, 5);
      expect(s.summary.connected, 1); // Alpha
      expect(s.summary.ready, 2); // Alpha + Beta
      expect(s.summary.setupRequired, 1); // Delta
      expect(s.summary.previewOnly, 1); // Epsilon
      expect(s.summary.syncSupported, 2); // Alpha + Epsilon
      expect(s.summary.intervention, 1); // Gamma
      expect(s.summary.adminRequired, 0);
    });

    test('rows sort intervention → setup → ready/connected → other, then name',
        () {
      final s = computeBaglantilarSnapshot(
        platforms: _sample(),
        canManage: true,
        officeGrounded: true,
      );
      expect(
        s.rows.map((r) => r.platformName).toList(),
        ['Gamma', 'Delta', 'Alpha', 'Beta', 'Epsilon'],
      );
    });

    test('status labels and tones are honest per lifecycle/truth', () {
      final s = computeBaglantilarSnapshot(
        platforms: _sample(),
        canManage: true,
        officeGrounded: true,
      );
      final byName = {for (final r in s.rows) r.platformName: r};

      expect(byName['Alpha']!.isConnected, isTrue);
      expect(byName['Alpha']!.statusLabel, 'Bağlı (canlı)');
      expect(byName['Alpha']!.tone, BaglantiTone.success);

      expect(byName['Beta']!.isReady, isTrue);
      expect(byName['Beta']!.statusLabel, 'İçe aktarmaya hazır');
      expect(byName['Beta']!.tone, BaglantiTone.success);

      expect(byName['Gamma']!.needsAction, isTrue);
      expect(byName['Gamma']!.statusLabel, 'Hata');
      expect(byName['Gamma']!.tone, BaglantiTone.danger);

      expect(byName['Delta']!.needsSetup, isTrue);
      expect(byName['Delta']!.statusLabel, 'Kurulum gerekli');
      expect(byName['Delta']!.tone, BaglantiTone.warning);

      expect(byName['Epsilon']!.isPreview, isTrue);
      expect(byName['Epsilon']!.statusLabel, 'Önizleme');
      expect(byName['Epsilon']!.tone, BaglantiTone.info);
    });

    test('capability pills reflect real capabilities', () {
      final s = computeBaglantilarSnapshot(
        platforms: [
          _p(
            name: 'Caps',
            truth: PlatformConnectionTruthKind.mockDemo,
            canImport: true,
            canSync: true,
            canPrice: true,
            canMessages: true,
          ),
        ],
        canManage: true,
        officeGrounded: true,
      );
      expect(
        s.rows.single.capabilityPills,
        ['İçe aktarma', 'Senkron', 'Fiyat', 'Mesaj'],
      );
    });

    test('canManage gates connect/configure/retry and admin flags', () {
      final managed = computeBaglantilarSnapshot(
        platforms: _sample(),
        canManage: true,
        officeGrounded: true,
      );
      final notManaged = computeBaglantilarSnapshot(
        platforms: _sample(),
        canManage: false,
        officeGrounded: true,
      );

      final delta = managed.rows.firstWhere((r) => r.platformName == 'Delta');
      expect(delta.canConnect, isTrue);
      expect(delta.canConfigure, isTrue);
      expect(delta.canRetry, isTrue);
      expect(delta.needsAdmin, isFalse);

      final deltaNo =
          notManaged.rows.firstWhere((r) => r.platformName == 'Delta');
      expect(deltaNo.canConnect, isFalse);
      expect(deltaNo.canConfigure, isFalse);
      expect(deltaNo.canRetry, isFalse);
      expect(deltaNo.needsAdmin, isTrue);
      expect(notManaged.summary.adminRequired, 5);
    });

    test('connected/ready rows cannot connect again', () {
      final s = computeBaglantilarSnapshot(
        platforms: _sample(),
        canManage: true,
        officeGrounded: true,
      );
      final alpha = s.rows.firstWhere((r) => r.platformName == 'Alpha');
      final beta = s.rows.firstWhere((r) => r.platformName == 'Beta');
      expect(alpha.canConnect, isFalse);
      expect(beta.canConnect, isFalse);
    });

    test('coverage note widens when office is not grounded', () {
      final grounded = computeBaglantilarSnapshot(
        platforms: _sample(),
        canManage: true,
        officeGrounded: true,
      );
      final notGrounded = computeBaglantilarSnapshot(
        platforms: _sample(),
        canManage: true,
        officeGrounded: false,
      );
      expect(grounded.coverageNote, isNot(contains('Ofis kimliği çözülene')));
      expect(notGrounded.coverageNote, contains('Ofis kimliği çözülene'));
      expect(grounded.coverageNote, contains('Bağlı'));
    });

    test('empty input yields empty snapshot', () {
      final s = computeBaglantilarSnapshot(
        platforms: const [],
        canManage: true,
        officeGrounded: true,
      );
      expect(s.isEmpty, isTrue);
      expect(s.rows, isEmpty);
      expect(s.summary.total, 0);
    });
  });

  group('filterBaglantilarRows', () {
    List<BaglantiRowViewModel> rows() => computeBaglantilarSnapshot(
          platforms: _sample(),
          canManage: true,
          officeGrounded: true,
        ).rows;

    test('search matches platform name', () {
      final out = filterBaglantilarRows(
        rows(),
        query: 'gamma',
        filter: BaglantilarFilter.all,
      );
      expect(out.map((r) => r.platformName), ['Gamma']);
    });

    test('search matches account label', () {
      final out = filterBaglantilarRows(
        rows(),
        query: 'alpha@office',
        filter: BaglantilarFilter.all,
      );
      expect(out.single.platformName, 'Alpha');
    });

    test('filter connected', () {
      final out = filterBaglantilarRows(
        rows(),
        query: '',
        filter: BaglantilarFilter.connected,
      );
      expect(out.map((r) => r.platformName), ['Alpha']);
    });

    test('filter ready', () {
      final out = filterBaglantilarRows(
        rows(),
        query: '',
        filter: BaglantilarFilter.ready,
      );
      expect(out.map((r) => r.platformName).toSet(), {'Alpha', 'Beta'});
    });

    test('filter setup', () {
      final out = filterBaglantilarRows(
        rows(),
        query: '',
        filter: BaglantilarFilter.setup,
      );
      expect(out.map((r) => r.platformName), ['Delta']);
    });

    test('filter intervention', () {
      final out = filterBaglantilarRows(
        rows(),
        query: '',
        filter: BaglantilarFilter.intervention,
      );
      expect(out.map((r) => r.platformName), ['Gamma']);
    });

    test('filter sync', () {
      final out = filterBaglantilarRows(
        rows(),
        query: '',
        filter: BaglantilarFilter.sync,
      );
      expect(out.map((r) => r.platformName).toSet(), {'Alpha', 'Epsilon'});
    });

    test('search + filter compose', () {
      final out = filterBaglantilarRows(
        rows(),
        query: 'a',
        filter: BaglantilarFilter.ready,
      );
      // Alpha and Beta are ready and both contain "a" in search text.
      expect(out.map((r) => r.platformName).toSet(), {'Alpha', 'Beta'});
    });
  });
}
