import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_memory_store.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_entity.dart';

/// İlanlar — yerel mağaza (Phase 1.5); ileride `listings` koleksiyonu ile birleştirilebilir.
class ListingsRepository {
  ListingsRepository._();
  static final ListingsRepository instance = ListingsRepository._();

  Stream<List<ListingEntity>> watchForOwner(String uid) =>
      ListingImportMemoryStore.instance.watchListings(uid);

  List<ListingEntity> snapshot(String uid) =>
      ListingImportMemoryStore.instance.listingsSnapshot(uid);

  void upsert(String uid, ListingEntity listing) {
    ListingImportMemoryStore.instance.upsertListing(uid, listing);
  }

  void updateFavorite(String uid, String listingId, bool value) {
    final list = snapshot(uid);
    final i = list.indexWhere((l) => l.id == listingId);
    if (i < 0) return;
    ListingImportMemoryStore.instance.upsertListing(uid, list[i].copyWith(isFavorite: value));
  }

  void updateNote(String uid, String listingId, String? note) {
    final list = snapshot(uid);
    final i = list.indexWhere((l) => l.id == listingId);
    if (i < 0) return;
    ListingImportMemoryStore.instance.upsertListing(uid, list[i].copyWith(quickNote: note));
  }
}
