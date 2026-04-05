import 'package:emlakmaster_mobile/features/external_integrations/application/platform_setup_lifecycle_logic.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_connection_mode.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_setup_status.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_lifecycle.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_record.dart';
import 'package:flutter_test/flutter_test.dart';

PlatformSetupRecord _base({
  required IntegrationConnectionMode mode,
  String? store,
  String? email,
  String? transfer,
  String? ref,
  bool setupCompleted = false,
  bool awaitingVerification = false,
  bool defer = false,
  bool oauth = false,
  IntegrationSetupStatus stored = IntegrationSetupStatus.inProgress,
}) {
  final now = DateTime(2026, 1, 1);
  return PlatformSetupRecord(
    platform: IntegrationPlatformId.sahibinden,
    officeId: 'o1',
    ownerUserId: 'u1',
    connectionMode: mode,
    setupStatus: stored,
    storeName: store,
    contactEmail: email,
    transferKey: transfer,
    integrationReference: ref,
    setupCompleted: setupCompleted,
    awaitingVerification: awaitingVerification,
    deferImportWorkflow: defer,
    oauthVerified: oauth,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('deriveLifecycleState', () {
    test('empty meaningful fields → notStarted', () {
      final r = _base(mode: IntegrationConnectionMode.officialSetup);
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.notStarted);
    });

    test('only storeName → incomplete', () {
      final r = _base(mode: IntegrationConnectionMode.officialSetup, store: 'Mağaza');
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.incomplete);
    });

    test('only email → incomplete', () {
      final r = _base(mode: IntegrationConnectionMode.officialSetup, email: 'a@b.co');
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.incomplete);
    });

    test('official complete without setupCompleted → officialPartnerPending', () {
      final r = _base(
        mode: IntegrationConnectionMode.officialSetup,
        store: 'Mağaza',
        email: 'a@b.co',
      );
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.officialPartnerPending);
    });

    test('official complete + setupCompleted → readyForImport', () {
      final r = _base(
        mode: IntegrationConnectionMode.officialSetup,
        store: 'Mağaza',
        email: 'a@b.co',
        setupCompleted: true,
      );
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.readyForImport);
    });

    test('transfer without key/ref → incomplete', () {
      final r = _base(
        mode: IntegrationConnectionMode.transferKey,
        store: 'M',
        email: 'a@b.co',
      );
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.incomplete);
    });

    test('transfer with key → readyForImport', () {
      final r = _base(
        mode: IntegrationConnectionMode.transferKey,
        store: 'M',
        email: 'a@b.co',
        transfer: 'KEY',
      );
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.readyForImport);
    });

    test('awaitingVerification only when complete + toggle', () {
      final r = _base(
        mode: IntegrationConnectionMode.fileImport,
        store: 'M',
        email: 'a@b.co',
        awaitingVerification: true,
      );
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.awaitingVerification);
    });

    test('defer defers ready and verification', () {
      final r = _base(
        mode: IntegrationConnectionMode.fileImport,
        store: 'M',
        email: 'a@b.co',
        defer: true,
        awaitingVerification: true,
      );
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.draft);
    });

    test('oauthVerified → liveEnabled', () {
      final r = _base(
        mode: IntegrationConnectionMode.manualOnly,
        store: 'M',
        email: 'a@b.co',
        oauth: true,
      );
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.liveEnabled);
    });

    test('stored error → error', () {
      final r = _base(
        mode: IntegrationConnectionMode.officialSetup,
        stored: IntegrationSetupStatus.error,
      );
      expect(deriveLifecycleState(r), PlatformSetupLifecycleState.error);
    });
  });
}
