import '../domain/integration_platform.dart';
import '../domain/integration_setup_status.dart';
import '../domain/platform_connection_truth_kind.dart';
import '../domain/platform_connection_ui_state.dart';
import '../domain/platform_error_ui.dart';
import '../domain/platform_setup_record.dart';

/// Mock kart + kurulum kaydı → dürüst görünüm (OAuth yoksa [liveConnected] üretilmez).
IntegrationPlatform mergePlatformWithSetup({
  required IntegrationPlatform base,
  required PlatformSetupRecord? record,
}) {
  if (record == null) return base;

  final truth = _truthFromSetup(record);
  final uiState = _uiStateFromSetup(record);

  final err = _errorFromSetup(record);

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

PlatformConnectionTruthKind _truthFromSetup(PlatformSetupRecord r) {
  if (r.oauthVerified) {
    return PlatformConnectionTruthKind.liveConnected;
  }
  switch (r.setupStatus) {
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

PlatformConnectionUiState _uiStateFromSetup(PlatformSetupRecord r) {
  switch (r.setupStatus) {
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

PlatformErrorUi? _errorFromSetup(PlatformSetupRecord r) {
  if (r.setupStatus == IntegrationSetupStatus.error) {
    return PlatformErrorUi(
      shortMessage: r.notes?.isNotEmpty == true ? r.notes! : 'Kurulum hatası kaydedildi.',
      hint: 'Sihirbazdan düzenleyin veya destek ile iletişime geçin.',
    );
  }
  if (r.setupStatus == IntegrationSetupStatus.awaitingVerification) {
    return PlatformErrorUi(
      shortMessage: 'Doğrulama bekleniyor',
      hint: r.applicationStatus?.isNotEmpty == true
          ? 'Başvuru: ${r.applicationStatus}'
          : 'Partner / platform onayı sonrası devam edilecek.',
    );
  }
  if (r.oauthVerified) return null;
  if (r.setupStatus == IntegrationSetupStatus.readyForImport) {
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
