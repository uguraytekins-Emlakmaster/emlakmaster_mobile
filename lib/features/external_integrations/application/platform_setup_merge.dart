import '../domain/integration_platform.dart';
import '../domain/integration_setup_status.dart';
import '../domain/platform_connection_truth_kind.dart';
import '../domain/platform_connection_ui_state.dart';
import '../domain/platform_error_ui.dart';
import '../domain/platform_setup_record.dart';
import 'platform_setup_completeness.dart';

/// Mock kart + kurulum kaydı → dürüst görünüm (OAuth yoksa [liveConnected] üretilmez).
IntegrationPlatform mergePlatformWithSetup({
  required IntegrationPlatform base,
  required PlatformSetupRecord? record,
}) {
  if (record == null) return base;

  final derived = deriveSetupStatusForRecord(record);
  final evaluation = evaluatePlatformSetup(record);
  final truth = _truthFromDerived(derived, record);
  final uiState = _uiStateFromDerived(derived, record);

  final err = _errorFromDerived(derived, evaluation, record);

  return IntegrationPlatform(
    id: base.id,
    name: base.name,
    logoLabel: base.logoLabel,
    supportLevel: base.supportLevel,
    capabilities: base.capabilities,
    connectionState: uiState,
    truthKind: truth,
    lastSyncAt: record.lastSyncAt,
    errorState: err,
    connectedAccountLabel: _labelFromRecord(record),
    setupRecord: record,
  );
}

PlatformConnectionTruthKind _truthFromDerived(
  IntegrationSetupStatus derived,
  PlatformSetupRecord r,
) {
  if (r.oauthVerified) {
    return PlatformConnectionTruthKind.liveConnected;
  }
  switch (derived) {
    case IntegrationSetupStatus.notStarted:
      return PlatformConnectionTruthKind.mockDemo;
    case IntegrationSetupStatus.inProgress:
      return PlatformConnectionTruthKind.preparing;
    case IntegrationSetupStatus.awaitingVerification:
      return PlatformConnectionTruthKind.setupIncomplete;
    case IntegrationSetupStatus.readyForImport:
      return PlatformConnectionTruthKind.experimentalNotLive;
    case IntegrationSetupStatus.liveEnabled:
      return PlatformConnectionTruthKind.preparing;
    case IntegrationSetupStatus.blocked:
      return PlatformConnectionTruthKind.liveNotEnabled;
    case IntegrationSetupStatus.error:
      return PlatformConnectionTruthKind.setupIncomplete;
  }
}

PlatformConnectionUiState _uiStateFromDerived(
  IntegrationSetupStatus derived,
  PlatformSetupRecord r,
) {
  switch (derived) {
    case IntegrationSetupStatus.notStarted:
      return PlatformConnectionUiState.disconnected;
    case IntegrationSetupStatus.inProgress:
      return PlatformConnectionUiState.disconnected;
    case IntegrationSetupStatus.awaitingVerification:
      return PlatformConnectionUiState.needsAttention;
    case IntegrationSetupStatus.readyForImport:
      return PlatformConnectionUiState.limited;
    case IntegrationSetupStatus.liveEnabled:
      return r.oauthVerified
          ? PlatformConnectionUiState.connected
          : PlatformConnectionUiState.limited;
    case IntegrationSetupStatus.blocked:
    case IntegrationSetupStatus.error:
      return PlatformConnectionUiState.needsAttention;
  }
}

PlatformErrorUi? _errorFromDerived(
  IntegrationSetupStatus derived,
  PlatformSetupEvaluation evaluation,
  PlatformSetupRecord r,
) {
  if (r.setupStatus == IntegrationSetupStatus.error) {
    return PlatformErrorUi(
      shortMessage: r.notes?.isNotEmpty == true ? r.notes! : 'Kurulum hatası kaydedildi.',
      hint: 'Sihirbazdan düzenleyin veya destek ile iletişime geçin.',
    );
  }

  if (derived == IntegrationSetupStatus.inProgress) {
    if (evaluation.isMeaningful && !evaluation.isComplete) {
      final hint = evaluation.missingHints.isEmpty
          ? 'Temel bilgiler eksik. Sihirbazı tamamlayın.'
          : 'Eksik: ${evaluation.missingHints.join(', ')}';
      return PlatformErrorUi(
        shortMessage: 'Kurulum tamamlanmadı',
        hint: hint,
      );
    }
    if (evaluation.isComplete && r.deferImportWorkflow) {
      return const PlatformErrorUi(
        shortMessage: 'Taslak kayıt',
        hint: 'İçe aktarma veya doğrulama adımları henüz başlatılmadı. Sihirbazı tamamlayın.',
      );
    }
  }

  if (derived == IntegrationSetupStatus.awaitingVerification) {
    return PlatformErrorUi(
      shortMessage: 'Doğrulama bekleniyor',
      hint: r.applicationStatus?.isNotEmpty == true
          ? 'Başvuru: ${r.applicationStatus}'
          : 'Partner / platform onayı sonrası devam edilecek.',
    );
  }
  if (r.oauthVerified) return null;
  if (derived == IntegrationSetupStatus.readyForImport) {
    return const PlatformErrorUi(
      shortMessage: 'Canlı otomatik senkron henüz aktif değil.',
      hint: 'Mağaza dışa aktarım dosyası ile toplu içe aktarmayı kullanın.',
    );
  }
  return null;
}

String? _labelFromRecord(PlatformSetupRecord r) {
  final name = r.storeName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return null;
}
