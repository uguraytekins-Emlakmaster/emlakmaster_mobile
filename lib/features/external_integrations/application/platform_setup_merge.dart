import '../domain/integration_connection_mode.dart';
import '../domain/integration_platform.dart';
import '../domain/integration_setup_status.dart';
import '../domain/platform_connection_truth_kind.dart';
import '../domain/platform_connection_ui_state.dart';
import '../domain/platform_error_ui.dart';
import '../domain/platform_setup_lifecycle.dart';
import '../domain/platform_setup_record.dart';
import 'platform_setup_completeness.dart';
import 'platform_setup_lifecycle_logic.dart';

/// Mock kart + kurulum kaydı → dürüst görünüm (OAuth yoksa [liveConnected] üretilmez).
IntegrationPlatform mergePlatformWithSetup({
  required IntegrationPlatform base,
  required PlatformSetupRecord? record,
}) {
  if (record == null) return base;

  final lifecycle = deriveLifecycleState(record);
  final evaluation = evaluatePlatformSetup(record);
  final truth = _truthFromLifecycle(lifecycle, record);
  final uiState = _uiStateFromLifecycle(lifecycle, record);

  final err = _errorFromLifecycle(lifecycle, evaluation, record);

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
    setupLifecycle: lifecycle,
  );
}

PlatformConnectionTruthKind _truthFromLifecycle(
  PlatformSetupLifecycleState lifecycle,
  PlatformSetupRecord r,
) {
  if (r.oauthVerified || lifecycle == PlatformSetupLifecycleState.liveEnabled) {
    return PlatformConnectionTruthKind.liveConnected;
  }
  switch (lifecycle) {
    case PlatformSetupLifecycleState.notStarted:
      return PlatformConnectionTruthKind.mockDemo;
    case PlatformSetupLifecycleState.incomplete:
      return PlatformConnectionTruthKind.setupIncomplete;
    case PlatformSetupLifecycleState.draft:
      return PlatformConnectionTruthKind.preparing;
    case PlatformSetupLifecycleState.awaitingVerification:
      return PlatformConnectionTruthKind.setupIncomplete;
    case PlatformSetupLifecycleState.officialPartnerPending:
      return PlatformConnectionTruthKind.preparing;
    case PlatformSetupLifecycleState.readyForImport:
      if (r.connectionMode == IntegrationConnectionMode.manualOnly) {
        return PlatformConnectionTruthKind.preparing;
      }
      return PlatformConnectionTruthKind.experimentalNotLive;
    case PlatformSetupLifecycleState.liveEnabled:
      return PlatformConnectionTruthKind.liveConnected;
    case PlatformSetupLifecycleState.blocked:
      return PlatformConnectionTruthKind.liveNotEnabled;
    case PlatformSetupLifecycleState.error:
      return PlatformConnectionTruthKind.setupIncomplete;
  }
}

PlatformConnectionUiState _uiStateFromLifecycle(
  PlatformSetupLifecycleState lifecycle,
  PlatformSetupRecord r,
) {
  switch (lifecycle) {
    case PlatformSetupLifecycleState.notStarted:
    case PlatformSetupLifecycleState.incomplete:
    case PlatformSetupLifecycleState.draft:
      return PlatformConnectionUiState.disconnected;
    case PlatformSetupLifecycleState.awaitingVerification:
    case PlatformSetupLifecycleState.officialPartnerPending:
    case PlatformSetupLifecycleState.blocked:
    case PlatformSetupLifecycleState.error:
      return PlatformConnectionUiState.needsAttention;
    case PlatformSetupLifecycleState.readyForImport:
      return PlatformConnectionUiState.limited;
    case PlatformSetupLifecycleState.liveEnabled:
      return r.oauthVerified
          ? PlatformConnectionUiState.connected
          : PlatformConnectionUiState.limited;
  }
}

PlatformErrorUi? _errorFromLifecycle(
  PlatformSetupLifecycleState lifecycle,
  PlatformSetupEvaluation evaluation,
  PlatformSetupRecord r,
) {
  if (lifecycle == PlatformSetupLifecycleState.error ||
      r.setupStatus == IntegrationSetupStatus.error) {
    return PlatformErrorUi(
      shortMessage: r.notes?.isNotEmpty == true ? r.notes! : 'Kurulum hatası kaydedildi.',
      hint: 'Sihirbazdan düzenleyin veya destek ile iletişime geçin.',
    );
  }

  switch (lifecycle) {
    case PlatformSetupLifecycleState.incomplete:
      final hint = evaluation.missingHints.isEmpty
          ? 'Temel bilgiler eksik. Sihirbazı tamamlayın.'
          : 'Eksik: ${evaluation.missingHints.join(', ')}';
      return PlatformErrorUi(
        shortMessage: 'Kurulum tamamlanmadı',
        hint: hint,
      );
    case PlatformSetupLifecycleState.draft:
      return const PlatformErrorUi(
        shortMessage: 'Taslak kayıt',
        hint: 'İçe aktarma veya doğrulama henüz başlatılmadı. Sihirbazı tamamlayın.',
      );
    case PlatformSetupLifecycleState.awaitingVerification:
      return PlatformErrorUi(
        shortMessage: 'Doğrulama bekleniyor',
        hint: r.applicationStatus?.isNotEmpty == true
            ? 'Başvuru: ${r.applicationStatus}'
            : 'Partner / platform onayı sonrası devam edilecek.',
      );
    case PlatformSetupLifecycleState.officialPartnerPending:
      return const PlatformErrorUi(
        shortMessage: 'Resmi kurulum sürecinde',
        hint: 'Partner onayı veya başvuru tamamlanınca ilerleyebilirsiniz.',
      );
    case PlatformSetupLifecycleState.readyForImport:
      if (r.connectionMode == IntegrationConnectionMode.manualOnly) {
        return const PlatformErrorUi(
          shortMessage: 'Manuel portföy modu',
          hint: 'Otomatik platform bağlantısı yok; ilanlar tek tek girilir.',
        );
      }
      return const PlatformErrorUi(
        shortMessage: 'Canlı otomatik senkron henüz aktif değil.',
        hint: 'Mağaza dışa aktarım dosyası ile toplu içe aktarmayı kullanın.',
      );
    case PlatformSetupLifecycleState.blocked:
      return const PlatformErrorUi(
        shortMessage: 'Bağlantı engellendi',
        hint: 'Yönetici veya destek ile iletişime geçin.',
      );
    default:
      return null;
  }
}

String? _labelFromRecord(PlatformSetupRecord r) {
  final name = r.storeName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return null;
}
