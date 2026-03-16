import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/barter_swap_engine/domain/entities/swap_compatibility_result.dart';

/// Takas skoru Firestore'a yazar (Data Integrity: last_updated her zaman set edilir).
class SwapCompatibilityRepository {
  Future<void> saveSwapScore(SwapCompatibilityResult result) async {
    await FirestoreService.ensureInitialized();
    final ref = FirebaseFirestore.instance.collection(AppConstants.colListings).doc(result.listingId);
    await ref.set({
      AppConstants.fieldSwapCompatible: true,
      AppConstants.fieldSwapCompatibilityScore: result.score,
      AppConstants.fieldSwapCompatibilityVerdict: result.verdict.id,
      AppConstants.fieldSwapCompatibilityUpdatedAt: FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
