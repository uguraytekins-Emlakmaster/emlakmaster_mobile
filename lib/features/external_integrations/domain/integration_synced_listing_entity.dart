import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'integration_platform_id.dart';

/// Bağlantı senkronu ile gelen ilan satırı (`integration_listings` veya genişletilmiş `external_listings`).
/// Market Pulse [ExternalListingEntity] ile karışmaması için ayrı tip.
class IntegrationSyncedListingEntity extends Equatable {
  const IntegrationSyncedListingEntity({
    required this.id,
    required this.connectionId,
    required this.platform,
    required this.externalListingId,
    this.internalListingId,
    required this.title,
    this.description,
    this.price,
    this.currency,
    this.listingType,
    this.category,
    this.city,
    this.district,
    this.neighborhood,
    this.images = const [],
    this.status,
    required this.sourceUrl,
    this.platformUpdatedAt,
    required this.importedAt,
    this.syncedAt,
    this.syncHash,
    required this.ownerUserId,
    required this.officeId,
    this.canonicalListingId,
    this.duplicateGroupId,
    this.syncStatus,
    this.rawPayload,
    this.updatedAt,
  });

  final String id;
  final String connectionId;
  final IntegrationPlatformId platform;
  final String externalListingId;
  final String? internalListingId;
  final String title;
  final String? description;
  final double? price;
  final String? currency;
  final String? listingType;
  final String? category;
  final String? city;
  final String? district;
  final String? neighborhood;
  final List<String> images;
  final String? status;
  final String sourceUrl;
  final DateTime? platformUpdatedAt;
  final DateTime importedAt;
  final DateTime? syncedAt;
  final String? syncHash;
  final String ownerUserId;
  final String officeId;
  /// Aynı mülk için iç CRM ilanı (gelecekte `listings` koleksiyonu).
  final String? canonicalListingId;
  /// Yinelenen kayıtları gruplamak için (duplicate engine).
  final String? duplicateGroupId;
  /// Örn. synced | pending | error | stale
  final String? syncStatus;
  final Map<String, dynamic>? rawPayload;
  final DateTime? updatedAt;

  static IntegrationSyncedListingEntity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final platformKey = d['platform'] as String? ?? 'sahibinden';
    final platform = IntegrationPlatformId.tryParse(platformKey) ?? IntegrationPlatformId.sahibinden;
    Timestamp? ts(dynamic x) => x is Timestamp ? x : null;
    final imgs = d['images'];
    final raw = d['rawPayload'];
    return IntegrationSyncedListingEntity(
      id: doc.id,
      connectionId: d['connectionId'] as String? ?? '',
      platform: platform,
      externalListingId: d['externalListingId'] as String? ?? '',
      internalListingId: d['internalListingId'] as String?,
      title: d['title'] as String? ?? '',
      description: d['description'] as String?,
      price: (d['price'] as num?)?.toDouble(),
      currency: d['currency'] as String?,
      listingType: d['listingType'] as String?,
      category: d['category'] as String?,
      city: d['city'] as String?,
      district: d['district'] as String?,
      neighborhood: d['neighborhood'] as String?,
      images: imgs is List ? imgs.map((e) => '$e').toList() : const [],
      status: d['status'] as String?,
      sourceUrl: d['sourceUrl'] as String? ?? '',
      platformUpdatedAt: ts(d['platformUpdatedAt'])?.toDate(),
      importedAt: ts(d['importedAt'])?.toDate() ?? DateTime.now(),
      syncedAt: ts(d['syncedAt'])?.toDate(),
      syncHash: d['syncHash'] as String?,
      ownerUserId: d['ownerUserId'] as String? ?? '',
      officeId: d['officeId'] as String? ?? '',
      canonicalListingId: d['canonicalListingId'] as String?,
      duplicateGroupId: d['duplicateGroupId'] as String?,
      syncStatus: d['syncStatus'] as String?,
      rawPayload: raw is Map<String, dynamic> ? raw : null,
      updatedAt: ts(d['updatedAt'])?.toDate(),
    );
  }

  @override
  List<Object?> get props => [id, connectionId, externalListingId, title, syncedAt, duplicateGroupId];
}
