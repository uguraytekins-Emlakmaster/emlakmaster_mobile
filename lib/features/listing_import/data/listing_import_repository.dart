import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_import_task_entity.dart';

/// Kullanıcıya ait import görevleri (salt okuma).
class ListingImportRepository {
  ListingImportRepository._();
  static final ListingImportRepository instance = ListingImportRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(AppConstants.colListingImportTasks);

  Stream<List<ListingImportTaskEntity>> streamForOwner(String uid) {
    return _col
        .where('ownerUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(ListingImportTaskEntity.fromDoc).toList());
  }
}
