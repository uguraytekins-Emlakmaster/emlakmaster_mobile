import 'integration_setup_status.dart';

/// Tek doğruluk kaynağı: sihirbaz, kartlar ve özet — [IntegrationSetupStatus]’tan ayrı, çakışmasız anlamlar.
///
/// Geçişler [platform_setup_lifecycle_logic.dart] içinde kodlanır; ham Firestore [setupStatus] yalnızca kalıcılık içindir.
enum PlatformSetupLifecycleState {
  /// Kayıt yok veya hiç anlamlı alan yok.
  notStarted,

  /// Anlamlı veri var ama seçilen mod için zorunlu alanlar eksik.
  incomplete,

  /// Zorunlu alanlar tamam; kullanıcı akışı bilinçli olarak erteledi (defer).
  draft,

  /// Tam kurulum + platform doğrulama / onay süreci (yalnızca veri yeterliyse).
  awaitingVerification,

  /// Resmi kurulum: bilgiler tam, partner / başvuru adımı sürüyor ([setupCompleted] false).
  officialPartnerPending,

  /// Toplu içe aktarma veya transfer yolu işe hazır (canlı OAuth değildir).
  readyForImport,

  /// Gerçek OAuth/API doğrulandı.
  liveEnabled,

  /// Politika / engel (kalıcı [IntegrationSetupStatus.blocked]).
  blocked,

  /// Kalıcı hata kaydı ([IntegrationSetupStatus.error]).
  error,
}

extension PlatformSetupLifecycleStateX on PlatformSetupLifecycleState {
  /// Bağlı platform kartı alt satırı (ham [IntegrationSetupStatus] yerine).
  String get cardSubtitleTr {
    switch (this) {
      case PlatformSetupLifecycleState.notStarted:
        return 'Kurulum başlamadı';
      case PlatformSetupLifecycleState.incomplete:
        return 'Kurulum tamamlanmadı · temel bilgiler eksik';
      case PlatformSetupLifecycleState.draft:
        return 'Taslak kaydedildi · sihirbazı tamamlayın';
      case PlatformSetupLifecycleState.awaitingVerification:
        return 'Doğrulama bekleniyor';
      case PlatformSetupLifecycleState.officialPartnerPending:
        return 'Resmi kurulum sürecinde · partner / başvuru';
      case PlatformSetupLifecycleState.readyForImport:
        return 'Toplu içe aktarma hazır (dosya)';
      case PlatformSetupLifecycleState.liveEnabled:
        return 'Canlı bağlantı aktif';
      case PlatformSetupLifecycleState.blocked:
        return 'Engellenmiş';
      case PlatformSetupLifecycleState.error:
        return 'Kurulum hatası';
    }
  }

  /// Durum rozeti metni — [PlatformConnectionTruthKind] rengiyle birlikte; canlı iddiası yok.
  String get chipLabelTr {
    switch (this) {
      case PlatformSetupLifecycleState.notStarted:
        return 'Başlamadı';
      case PlatformSetupLifecycleState.incomplete:
        return 'Eksik kurulum';
      case PlatformSetupLifecycleState.draft:
        return 'Taslak';
      case PlatformSetupLifecycleState.awaitingVerification:
        return 'Doğrulama bekleniyor';
      case PlatformSetupLifecycleState.officialPartnerPending:
        return 'Süreçte';
      case PlatformSetupLifecycleState.readyForImport:
        return 'İçe aktarmaya hazır';
      case PlatformSetupLifecycleState.liveEnabled:
        return 'Canlı';
      case PlatformSetupLifecycleState.blocked:
        return 'Engelli';
      case PlatformSetupLifecycleState.error:
        return 'Hata';
    }
  }

  /// [IntegrationSetupStatus] ile geriye dönük eşleme (Firestore / eski UI).
  IntegrationSetupStatus get approximateIntegrationStatus {
    switch (this) {
      case PlatformSetupLifecycleState.notStarted:
        return IntegrationSetupStatus.notStarted;
      case PlatformSetupLifecycleState.incomplete:
      case PlatformSetupLifecycleState.draft:
      case PlatformSetupLifecycleState.officialPartnerPending:
        return IntegrationSetupStatus.inProgress;
      case PlatformSetupLifecycleState.awaitingVerification:
        return IntegrationSetupStatus.awaitingVerification;
      case PlatformSetupLifecycleState.readyForImport:
        return IntegrationSetupStatus.readyForImport;
      case PlatformSetupLifecycleState.liveEnabled:
        return IntegrationSetupStatus.liveEnabled;
      case PlatformSetupLifecycleState.blocked:
        return IntegrationSetupStatus.blocked;
      case PlatformSetupLifecycleState.error:
        return IntegrationSetupStatus.error;
    }
  }

  bool get countsAsAttentionForDashboard {
    switch (this) {
      case PlatformSetupLifecycleState.incomplete:
      case PlatformSetupLifecycleState.awaitingVerification:
      case PlatformSetupLifecycleState.officialPartnerPending:
      case PlatformSetupLifecycleState.error:
        return true;
      case PlatformSetupLifecycleState.notStarted:
      case PlatformSetupLifecycleState.draft:
      case PlatformSetupLifecycleState.readyForImport:
      case PlatformSetupLifecycleState.liveEnabled:
      case PlatformSetupLifecycleState.blocked:
        return false;
    }
  }
}
