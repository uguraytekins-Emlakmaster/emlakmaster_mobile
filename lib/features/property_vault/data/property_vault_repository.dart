import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/property_vault/domain/entities/property_vault_item.dart';

/// Mülk Sağlık Karnesi: listing alt koleksiyonu property_vault.
class PropertyVaultRepository {
  static String get _vaultCol => AppConstants.colPropertyVault;

  static Stream<QuerySnapshot<Map<String, dynamic>>> vaultStream(String listingId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.colListings)
        .doc(listingId)
        .collection(_vaultCol)
        .orderBy('occurredAt', descending: true)
        .limit(50)
        .snapshots();
  }

  static Future<void> addItem({
    required String listingId,
    required PropertyVaultItemType type,
    String? title,
    String? description,
    String? attachmentUrl,
    DateTime? occurredAt,
  }) async {
    await FirestoreService.ensureInitialized();
    final col = FirebaseFirestore.instance
        .collection(AppConstants.colListings)
        .doc(listingId)
        .collection(_vaultCol);
    await col.add({
      'listingId': listingId,
      'type': type.id,
      'title': title,
      'description': description,
      'attachmentUrl': attachmentUrl,
      'occurredAt': occurredAt != null ? Timestamp.fromDate(occurredAt) : FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
