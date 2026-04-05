/// Ofis kurulumunda seçilen bağlantı modu — OAuth sahtesi değil, iş kuralı etiketi.
enum IntegrationConnectionMode {
  /// Resmi API / partner onayı ile kurulum (henüz canlı olmayabilir).
  officialSetup,

  /// Transfer anahtarı veya partner referansı ile eşleme.
  transferKey,

  /// CSV / JSON / XLSX toplu içe aktarma.
  fileImport,

  /// Yalnızca manuel portföy.
  manualOnly,
}

extension IntegrationConnectionModeX on IntegrationConnectionMode {
  String get labelTr {
    switch (this) {
      case IntegrationConnectionMode.officialSetup:
        return 'Resmi entegrasyon kurulumu';
      case IntegrationConnectionMode.transferKey:
        return 'Transfer anahtarı / partner referansı';
      case IntegrationConnectionMode.fileImport:
        return 'Dosya ile toplu içe aktarma';
      case IntegrationConnectionMode.manualOnly:
        return 'Manuel portföy';
    }
  }
}
