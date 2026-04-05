import '../domain/integration_connection_mode.dart';
import '../domain/integration_setup_status.dart';
import '../domain/platform_setup_record.dart';

/// Sihirbaz ve kartlar için ortak: anlamlı veri / tam kurulum / doğrulamaya hazır.
class PlatformSetupEvaluation {
  const PlatformSetupEvaluation({
    required this.isMeaningful,
    required this.isComplete,
    required this.isVerificationReady,
    this.missingHints = const [],
  });

  /// En az bir alan dolu (taslak / başlangıç).
  final bool isMeaningful;

  /// Seçilen mod için zorunlu alanlar tamam.
  final bool isComplete;

  /// Doğrulama bekleniyor durumu anlamlı olabilir (tam kurulum + onay süreci).
  final bool isVerificationReady;

  /// Eksik alanlar (UI ipucu).
  final List<String> missingHints;
}

bool _nonEmpty(String? s) => s != null && s.trim().isNotEmpty;

/// Basit e-posta kontrolü (tam RFC değil; yanlış pozitif kabul edilebilir).
bool isPlausibleContactEmail(String? s) {
  if (!_nonEmpty(s)) return false;
  final t = s!.trim();
  final at = t.indexOf('@');
  return at > 0 && at < t.length - 1 && !t.contains(' ');
}

/// Kayıt alanlarından tamamlanma değerlendirmesi.
PlatformSetupEvaluation evaluatePlatformSetup(PlatformSetupRecord r) {
  final store = r.storeName?.trim();
  final email = r.contactEmail?.trim();
  final transfer = r.transferKey?.trim();
  final ref = r.integrationReference?.trim();
  final hasTransferOrRef = _nonEmpty(transfer) || _nonEmpty(ref);

  final meaningful = _nonEmpty(store) ||
      isPlausibleContactEmail(email) ||
      _nonEmpty(transfer) ||
      _nonEmpty(ref) ||
      _nonEmpty(r.companyInfo?.trim());

  final hints = <String>[];
  if (!_nonEmpty(store)) hints.add('Mağaza / ofis adı');
  if (!isPlausibleContactEmail(email)) hints.add('Geçerli iletişim e-postası');

  switch (r.connectionMode) {
    case IntegrationConnectionMode.officialSetup:
    case IntegrationConnectionMode.fileImport:
    case IntegrationConnectionMode.manualOnly:
      break;
    case IntegrationConnectionMode.transferKey:
      if (!hasTransferOrRef) {
        hints.add('Transfer anahtarı veya partner referansı');
      }
      break;
  }

  final complete = _isCompleteForMode(
    mode: r.connectionMode,
    storeNonEmpty: _nonEmpty(store),
    emailOk: isPlausibleContactEmail(email),
    hasTransferOrRef: hasTransferOrRef,
  );

  return PlatformSetupEvaluation(
    isMeaningful: meaningful,
    isComplete: complete,
    isVerificationReady: complete,
    missingHints: hints,
  );
}

bool _isCompleteForMode({
  required IntegrationConnectionMode mode,
  required bool storeNonEmpty,
  required bool emailOk,
  required bool hasTransferOrRef,
}) {
  switch (mode) {
    case IntegrationConnectionMode.officialSetup:
    case IntegrationConnectionMode.fileImport:
    case IntegrationConnectionMode.manualOnly:
      return storeNonEmpty && emailOk;
    case IntegrationConnectionMode.transferKey:
      return storeNonEmpty && emailOk && hasTransferOrRef;
  }
}

/// Firestore’daki ham [setupStatus] yerine kart ve sihirbaz için tek doğruluk.
/// [PlatformSetupRecord.deferImportWorkflow]: 4. adımda “önce kayıt” — hazır/akış iddiasını erteler.
IntegrationSetupStatus deriveSetupStatusForRecord(PlatformSetupRecord r) {
  if (r.oauthVerified) {
    return IntegrationSetupStatus.liveEnabled;
  }

  final e = evaluatePlatformSetup(r);

  if (!e.isMeaningful) {
    return IntegrationSetupStatus.notStarted;
  }
  if (!e.isComplete) {
    return IntegrationSetupStatus.inProgress;
  }

  if (r.deferImportWorkflow) {
    return IntegrationSetupStatus.inProgress;
  }

  final awaitingAllowed = r.awaitingVerification && e.isVerificationReady;
  if (awaitingAllowed) {
    return IntegrationSetupStatus.awaitingVerification;
  }

  switch (r.connectionMode) {
    case IntegrationConnectionMode.officialSetup:
      return r.setupCompleted
          ? IntegrationSetupStatus.readyForImport
          : IntegrationSetupStatus.inProgress;
    case IntegrationConnectionMode.transferKey:
    case IntegrationConnectionMode.fileImport:
    case IntegrationConnectionMode.manualOnly:
      return IntegrationSetupStatus.readyForImport;
  }
}
