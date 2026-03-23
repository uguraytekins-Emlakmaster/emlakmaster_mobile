import 'package:equatable/equatable.dart';

/// Platform destek seviyesi (UI rozetleri).
enum IntegrationSupportLevel {
  /// Tam resmi / sürdürülebilir entegrasyon hedefi
  tier1Official,
  /// Kullanıcı kontrollü içe aktarma / senkron
  tier2UserControlled,
  /// Deneysel veya kısıtlı
  tier3Experimental,
}

/// Platform yetenek matrisi — UI ve adapter davranışı tek kaynak.
class IntegrationCapabilitySet extends Equatable {
  const IntegrationCapabilitySet({
    this.canImportListings = false,
    this.canIncrementalSync = false,
    this.canReadMessages = false,
    this.canReplyMessages = false,
    this.canUpdatePrice = false,
    this.canUpdateStatus = false,
    this.canCreateListing = false,
    this.canDeleteListing = false,
    this.requiresManualExport = false,
    this.requiresReauth = false,
    this.supportsWebhook = false,
    this.supportsFeedImport = false,
    // Phase 1 — açık bayraklar (ileri fazlar gerçek implementasyon)
    this.canUseUrlImport = false,
    this.canUseFileImport = false,
    this.canUseBrowserExtension = false,
    this.hasOfficialSupport = false,
    this.supportLevel = IntegrationSupportLevel.tier2UserControlled,
  });

  final bool canImportListings;
  final bool canIncrementalSync;
  final bool canReadMessages;
  final bool canReplyMessages;
  final bool canUpdatePrice;
  final bool canUpdateStatus;
  final bool canCreateListing;
  final bool canDeleteListing;
  final bool requiresManualExport;
  /// OAuth süresi doldu vb. — UI’da «Yeniden bağlan»
  final bool requiresReauth;
  final bool supportsWebhook;
  final bool supportsFeedImport;

  final bool canUseUrlImport;
  final bool canUseFileImport;
  final bool canUseBrowserExtension;
  final bool hasOfficialSupport;
  final IntegrationSupportLevel supportLevel;

  /// `requiresReauth` ile aynı anlam (dokümantasyon adı).
  bool get requiresReconnect => requiresReauth;

  Map<String, dynamic> toJson() => {
        'canImportListings': canImportListings,
        'canIncrementalSync': canIncrementalSync,
        'canReadMessages': canReadMessages,
        'canReplyMessages': canReplyMessages,
        'canUpdatePrice': canUpdatePrice,
        'canUpdateStatus': canUpdateStatus,
        'canCreateListing': canCreateListing,
        'canDeleteListing': canDeleteListing,
        'requiresManualExport': requiresManualExport,
        'requiresReauth': requiresReauth,
        'supportsWebhook': supportsWebhook,
        'supportsFeedImport': supportsFeedImport,
        'canUseUrlImport': canUseUrlImport,
        'canUseFileImport': canUseFileImport,
        'canUseBrowserExtension': canUseBrowserExtension,
        'hasOfficialSupport': hasOfficialSupport,
        'supportLevel': supportLevel.name,
      };

  static IntegrationCapabilitySet fromJson(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const IntegrationCapabilitySet();
    bool b(String k) => map[k] == true;
    IntegrationSupportLevel level = IntegrationSupportLevel.tier2UserControlled;
    final ls = map['supportLevel'] as String?;
    if (ls != null) {
      for (final v in IntegrationSupportLevel.values) {
        if (v.name == ls) {
          level = v;
          break;
        }
      }
    }
    return IntegrationCapabilitySet(
      canImportListings: b('canImportListings'),
      canIncrementalSync: b('canIncrementalSync'),
      canReadMessages: b('canReadMessages'),
      canReplyMessages: b('canReplyMessages'),
      canUpdatePrice: b('canUpdatePrice'),
      canUpdateStatus: b('canUpdateStatus'),
      canCreateListing: b('canCreateListing'),
      canDeleteListing: b('canDeleteListing'),
      requiresManualExport: b('requiresManualExport'),
      requiresReauth: b('requiresReauth'),
      supportsWebhook: b('supportsWebhook'),
      supportsFeedImport: b('supportsFeedImport'),
      canUseUrlImport: b('canUseUrlImport'),
      canUseFileImport: b('canUseFileImport'),
      canUseBrowserExtension: b('canUseBrowserExtension'),
      hasOfficialSupport: b('hasOfficialSupport'),
      supportLevel: level,
    );
  }

  @override
  List<Object?> get props => [
        canImportListings,
        canIncrementalSync,
        canReadMessages,
        canReplyMessages,
        canUpdatePrice,
        canUpdateStatus,
        canCreateListing,
        canDeleteListing,
        requiresManualExport,
        requiresReauth,
        supportsWebhook,
        supportsFeedImport,
        canUseUrlImport,
        canUseFileImport,
        canUseBrowserExtension,
        hasOfficialSupport,
        supportLevel,
      ];
}
