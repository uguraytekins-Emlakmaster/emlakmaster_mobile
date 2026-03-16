import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/crm_customers/data/customer_mapper.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tek müşteri (customerId) için canlı CustomerEntity stream'i.
/// CallScreen, müşteri detay ve AI asistan paneli bu provider ile müşteri verisini alır.
final customerEntityByIdProvider = StreamProvider.family<CustomerEntity?, String>(
  (ref, customerId) {
    if (customerId.isEmpty) return Stream<CustomerEntity?>.value(null);
    return FirestoreService.customerStream(customerId).map((snap) =>
        CustomerMapper.fromDoc(snap));
  },
);
