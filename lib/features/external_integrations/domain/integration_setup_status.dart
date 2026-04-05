/// Kurulum yaşam döngüsü — canlı OAuth yoksa [liveEnabled] kullanılmaz.
enum IntegrationSetupStatus {
  notStarted,
  inProgress,
  awaitingVerification,
  readyForImport,
  liveEnabled,
  blocked,
  error,
}

extension IntegrationSetupStatusX on IntegrationSetupStatus {
  String get shortLabelTr {
    switch (this) {
      case IntegrationSetupStatus.notStarted:
        return 'Başlamadı';
      case IntegrationSetupStatus.inProgress:
        return 'Devam ediyor';
      case IntegrationSetupStatus.awaitingVerification:
        return 'Doğrulama bekleniyor';
      case IntegrationSetupStatus.readyForImport:
        return 'İçe aktarıma hazır';
      case IntegrationSetupStatus.liveEnabled:
        return 'Canlı senkron (doğrulanmış)';
      case IntegrationSetupStatus.blocked:
        return 'Engelli';
      case IntegrationSetupStatus.error:
        return 'Hata';
    }
  }
}
