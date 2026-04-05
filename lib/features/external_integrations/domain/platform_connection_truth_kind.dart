/// Bağlantı kartında gösterilen **gerçek** durum — OAuth/canlı API yoksa "Bağlı" denmez.
enum PlatformConnectionTruthKind {
  /// Resmi OAuth / API ile doğrulanmış canlı bağlantı (üretim).
  liveConnected,

  /// UI/demo mock — canlı entegrasyon değildir.
  mockDemo,

  /// Partner entegrasyonu yolda / yapılandırma bekleniyor.
  preparing,

  /// URL / heuristik içe aktarma gibi deneysel kanallar; üretim güvencesi yoktur.
  experimentalNotLive,

  /// Kurulum veya yetkilendirme tamamlanmadı.
  setupIncomplete,

  /// Canlı bağlantı bu ortamda kapalı veya henüz açılmadı.
  liveNotEnabled,
}

extension PlatformConnectionTruthKindX on PlatformConnectionTruthKind {
  /// Kısa rozet metni (Türkçe ürün dili).
  String get shortLabelTr {
    switch (this) {
      case PlatformConnectionTruthKind.liveConnected:
        return 'Bağlı (canlı)';
      case PlatformConnectionTruthKind.mockDemo:
        return 'Mock · canlı değil';
      case PlatformConnectionTruthKind.preparing:
        return 'Hazırlanıyor';
      case PlatformConnectionTruthKind.experimentalNotLive:
        return 'Deneysel · canlı değil';
      case PlatformConnectionTruthKind.setupIncomplete:
        return 'Kurulum tamamlanmadı';
      case PlatformConnectionTruthKind.liveNotEnabled:
        return 'Canlı entegrasyon aktif değil';
    }
  }

  bool get isLiveProduction => this == PlatformConnectionTruthKind.liveConnected;
}
