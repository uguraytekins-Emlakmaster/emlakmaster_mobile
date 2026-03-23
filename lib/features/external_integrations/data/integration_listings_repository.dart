import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';

import '../domain/integration_synced_listing_entity.dart';

/// Bağlı hesaplardan senkronize `integration_listings` satırları (salt okuma).
class IntegrationListingsRepository {
  IntegrationListingsRepository._();
  static final IntegrationListingsRepository instance = IntegrationListingsRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(AppConstants.colIntegrationListings);

  /// `ownerUserId` alanına göre sorgu (tek alan — basit index).
  Stream<List<IntegrationSyncedListingEntity>> streamForOwner(String ownerUserId) {
    return _col.where('ownerUserId', isEqualTo: ownerUserId).snapshots().map((snap) {
      final list = snap.docs.map(IntegrationSyncedListingEntity.fromDoc).toList();
      list.sort((a, b) {
        final ta = a.syncedAt ?? a.platformUpdatedAt ?? a.importedAt;
        final tb = b.syncedAt ?? b.platformUpdatedAt ?? b.importedAt;
        return tb.compareTo(ta);
      });
      return list;
    });
  }
}
