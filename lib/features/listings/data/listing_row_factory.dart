import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_synced_listing_entity.dart';
import 'package:emlakmaster_mobile/features/external_listings/domain/entities/external_listing_entity.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';

/// Firestore `listings` — ofis iç portföyü veya canonical owned (resmi senkron / içe aktarma).
ListingRowView listingRowFromInternalDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data() ?? {};
  final priceRaw = d['price'];
  final priceStr = priceRaw is String
      ? priceRaw
      : (priceRaw as num?)?.toString() ?? '—';
  final loc = d['location'] as String? ?? d['district'] as String? ?? '—';
  final sourcePlatform =
      (d['sourcePlatform'] as String? ?? d['source'] as String? ?? 'internal').trim();
  final sourceListingId = (d['sourceListingId'] as String? ?? doc.id).trim();
  final isOwned = d['isOwnedByOffice'] as bool? ?? true;
  final sp = sourcePlatform.toLowerCase();
  final isInternalOnly = sp == 'internal' ||
      sp == 'portfolio' ||
      sp.isEmpty ||
      sp == 'manual';
  return ListingRowView(
    id: doc.id,
    sourcePlatform: sourcePlatform.isEmpty ? 'internal' : sourcePlatform,
    sourceListingId: sourceListingId,
    isOwnedByOffice: isOwned,
    syncStatus: parseListingSyncStatus(d['syncStatus'] as String?),
    lastSyncedAt: (d['lastSyncedAt'] as Timestamp?)?.toDate(),
    contentHash: d['contentHash'] as String?,
    title: d['title'] as String? ?? '',
    priceLabel: priceStr,
    locationLabel: loc,
    imageUrl: d['imageUrl'] as String?,
    surface: ListingSurface.owned,
    rowKind: isInternalOnly ? ListingRowKind.officePortfolio : ListingRowKind.connectedPlatform,
    detailListingId: doc.id,
    openInBrowserUrl: null,
  );
}

/// `integration_listings` — resmi bağlantı senkronu.
ListingRowView listingRowFromIntegration(IntegrationSyncedListingEntity e) {
  final priceStr = e.price != null
      ? (e.currency != null && e.currency!.isNotEmpty
          ? '${e.price!.toStringAsFixed(0)} ${e.currency}'
          : e.price!.toStringAsFixed(0))
      : '—';
  final locParts = <String>[];
  if (e.city != null && e.city!.isNotEmpty) locParts.add(e.city!);
  if (e.district != null && e.district!.isNotEmpty) locParts.add(e.district!);
  final loc = locParts.join(' · ');
  final img = e.images.isNotEmpty ? e.images.first : null;
  return ListingRowView(
    id: 'int_${e.id}',
    sourcePlatform: e.platform.storageKey,
    sourceListingId: e.externalListingId.isNotEmpty ? e.externalListingId : e.id,
    isOwnedByOffice: true,
    syncStatus: parseListingSyncStatus(e.syncStatus),
    lastSyncedAt: e.syncedAt ?? e.platformUpdatedAt,
    contentHash: e.syncHash,
    title: e.title,
    priceLabel: priceStr,
    locationLabel: loc.isEmpty ? '—' : loc,
    imageUrl: img,
    surface: ListingSurface.owned,
    rowKind: ListingRowKind.connectedPlatform,
    openInBrowserUrl: e.sourceUrl.isNotEmpty ? e.sourceUrl : null,
    detailListingId: e.internalListingId,
    integrationDocId: e.id,
  );
}

/// Pazar akışı — `external_listings` (resmi ingest; birinci şahıs değil).
ListingRowView listingRowFromMarketFeed(ExternalListingEntity e) {
  final priceStr = (e.priceText != null && e.priceText!.isNotEmpty)
      ? e.priceText!
      : (e.priceValue != null ? e.priceValue!.toString() : '—');
  final locParts = <String>[e.city];
  if (e.district != null && e.district!.isNotEmpty) locParts.add(e.district!);
  return ListingRowView(
    id: 'mkt_${e.id}',
    sourcePlatform: 'market_${e.source.name}',
    sourceListingId: e.externalId,
    isOwnedByOffice: false,
    syncStatus: e.ingestedAt != null ? ListingSyncStatus.synced : ListingSyncStatus.unknown,
    lastSyncedAt: e.ingestedAt ?? e.postedAt,
    contentHash: null,
    title: e.title,
    priceLabel: priceStr,
    locationLabel: locParts.join(' · '),
    imageUrl: e.imageUrl,
    surface: ListingSurface.marketFeed,
    rowKind: ListingRowKind.market,
    openInBrowserUrl: e.link,
    detailListingId: null,
  );
}

IntegrationPlatformId? tryPlatformForRow(ListingRowView row) {
  return IntegrationPlatformId.tryParse(row.sourcePlatform);
}
