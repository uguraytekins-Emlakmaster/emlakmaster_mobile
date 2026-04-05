import '../domain/integration_connection_mode.dart';
import '../domain/integration_setup_status.dart';
import '../domain/platform_setup_lifecycle.dart';
import '../domain/platform_setup_record.dart';
import 'platform_setup_completeness.dart';

/// Tek giriş noktası: kayıttan türetilmiş yaşam döngüsü.
PlatformSetupLifecycleState deriveLifecycleState(PlatformSetupRecord r) {
  if (r.setupStatus == IntegrationSetupStatus.error) {
    return PlatformSetupLifecycleState.error;
  }
  if (r.setupStatus == IntegrationSetupStatus.blocked) {
    return PlatformSetupLifecycleState.blocked;
  }
  if (r.oauthVerified) {
    return PlatformSetupLifecycleState.liveEnabled;
  }

  final e = evaluatePlatformSetup(r);

  if (!e.isMeaningful) {
    return PlatformSetupLifecycleState.notStarted;
  }
  if (!e.isComplete) {
    return PlatformSetupLifecycleState.incomplete;
  }

  if (r.deferImportWorkflow) {
    return PlatformSetupLifecycleState.draft;
  }

  if (r.awaitingVerification && e.isVerificationReady) {
    return PlatformSetupLifecycleState.awaitingVerification;
  }

  switch (r.connectionMode) {
    case IntegrationConnectionMode.officialSetup:
      if (!r.setupCompleted) {
        return PlatformSetupLifecycleState.officialPartnerPending;
      }
      return PlatformSetupLifecycleState.readyForImport;
    case IntegrationConnectionMode.transferKey:
    case IntegrationConnectionMode.fileImport:
      return PlatformSetupLifecycleState.readyForImport;
    case IntegrationConnectionMode.manualOnly:
      return PlatformSetupLifecycleState.readyForImport;
  }
}

/// Firestore’da saklanan [IntegrationSetupStatus] — UI tek doğruluğu [deriveLifecycleState].
IntegrationSetupStatus integrationSetupStatusFromLifecycle(PlatformSetupLifecycleState s) {
  return s.approximateIntegrationStatus;
}

/// Eski [deriveSetupStatusForRecord] ile aynı çıktı (kalıcılık uyumu).
IntegrationSetupStatus deriveSetupStatusForRecord(PlatformSetupRecord r) {
  return integrationSetupStatusFromLifecycle(deriveLifecycleState(r));
}
