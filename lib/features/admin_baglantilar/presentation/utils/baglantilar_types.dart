// Bağlantılar — yalnızca gerçek platform kataloğu + Firestore platform_setups
// kayıtlarından türetilen tipler. Uydurma "bağlı" durumu, sahte senkron/webhook
// sağlığı veya sahte başarı metriği yok.

import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';

/// Yatay filtre seçenekleri (yalnızca grounded kategoriler).
enum BaglantilarFilter {
  all,
  connected,
  ready,
  setup,
  preview,
  admin,
  sync,
  intervention,
}

extension BaglantilarFilterLabel on BaglantilarFilter {
  String get label => switch (this) {
        BaglantilarFilter.all => 'Tümü',
        BaglantilarFilter.connected => 'Bağlı',
        BaglantilarFilter.ready => 'Hazır',
        BaglantilarFilter.setup => 'Kurulum',
        BaglantilarFilter.preview => 'Önizleme',
        BaglantilarFilter.admin => 'Admin',
        BaglantilarFilter.sync => 'Sync',
        BaglantilarFilter.intervention => 'Müdahale',
      };
}

/// Renk tonu — widget katmanında tema rengine eşlenir.
enum BaglantiTone { info, success, warning, danger, neutral }

class BaglantilarSummary {
  const BaglantilarSummary({
    required this.connected,
    required this.ready,
    required this.setupRequired,
    required this.previewOnly,
    required this.adminRequired,
    required this.syncSupported,
    required this.intervention,
    required this.total,
  });

  final int connected;
  final int ready;
  final int setupRequired;
  final int previewOnly;
  final int adminRequired;
  final int syncSupported;
  final int intervention;
  final int total;

  static const empty = BaglantilarSummary(
    connected: 0,
    ready: 0,
    setupRequired: 0,
    previewOnly: 0,
    adminRequired: 0,
    syncSupported: 0,
    intervention: 0,
    total: 0,
  );
}

class BaglantiRowViewModel {
  const BaglantiRowViewModel({
    required this.platformId,
    required this.platformName,
    required this.providerLine,
    required this.detailLine,
    required this.statusLabel,
    required this.tone,
    required this.capabilityPills,
    required this.needsAdmin,
    required this.searchText,
    // Türetilmiş bayraklar
    required this.isConnected,
    required this.isReady,
    required this.needsSetup,
    required this.isPreview,
    required this.supportsSync,
    required this.needsAction,
    // Aksiyon yetkileri (önceden hesaplanmış)
    required this.canConnect,
    required this.canConfigure,
    required this.canImport,
    required this.canRetry,
  });

  final IntegrationPlatformId platformId;
  final String platformName;
  final String providerLine;
  final String detailLine;
  final String statusLabel;
  final BaglantiTone tone;
  final List<String> capabilityPills;
  final bool needsAdmin;
  final String searchText;

  final bool isConnected;
  final bool isReady;
  final bool needsSetup;
  final bool isPreview;
  final bool supportsSync;
  final bool needsAction;

  final bool canConnect;
  final bool canConfigure;
  final bool canImport;
  final bool canRetry;

  String get id => 'platform:${platformId.storageKey}';
}

class BaglantilarSnapshot {
  const BaglantilarSnapshot({
    required this.rows,
    required this.summary,
    required this.coverageNote,
    required this.officeGrounded,
    required this.isEmpty,
  });

  final List<BaglantiRowViewModel> rows;
  final BaglantilarSummary summary;
  final String coverageNote;

  /// Ofis kimliği çözüldüyse (ofis bazlı kurulum kayıtları okunabiliyor) true.
  final bool officeGrounded;

  final bool isEmpty;
}
