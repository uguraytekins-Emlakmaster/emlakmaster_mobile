import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';

import '../domain/listing_sync_models.dart';

/// Ofis için `listing_sources` (resmi connector kayıtları) — salt okuma.
class ListingSourcesRepository {
  ListingSourcesRepository._();
  static final ListingSourcesRepository instance = ListingSourcesRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(AppConstants.colListingSources);

  Stream<List<ListingSourceDoc>> streamForOffice(String officeId) {
    if (officeId.isEmpty) {
      return Stream<List<ListingSourceDoc>>.value(const []);
    }
    return _col.where('officeId', isEqualTo: officeId).snapshots().map((snap) {
      final list = snap.docs.map(ListingSourceDoc.fromSnapshot).whereType<ListingSourceDoc>().toList();
      list.sort((a, b) => a.platform.compareTo(b.platform));
      return list;
    });
  }
}
