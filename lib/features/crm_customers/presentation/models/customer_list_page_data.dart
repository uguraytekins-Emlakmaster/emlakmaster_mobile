import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// İlk sayfa stream snapshot + sayfalama meta verisi.
class CustomerListPageData {
  const CustomerListPageData({
    required this.entities,
    this.hasMore = false,
    this.lastDocument,
  });

  final List<CustomerEntity> entities;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  static const empty = CustomerListPageData(entities: []);
}
