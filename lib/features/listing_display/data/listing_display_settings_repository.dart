import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/listing_display/domain/entities/listing_display_settings_entity.dart';

class ListingDisplaySettingsRepository {
  static Future<ListingDisplaySettingsEntity> get() async {
    await FirestoreService.ensureInitialized();
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colAppSettings)
        .doc(AppConstants.docListingDisplaySettings);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      return const ListingDisplaySettingsEntity();
    }
    return _fromMap(snap.data()!, snap.get('updatedAt') as Timestamp?);
  }

  static Stream<ListingDisplaySettingsEntity> stream() async* {
    await FirestoreService.ensureInitialized();
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colAppSettings)
        .doc(AppConstants.docListingDisplaySettings)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) {
        return const ListingDisplaySettingsEntity();
      }
      return _fromMap(snap.data()!, snap.get('updatedAt') as Timestamp?);
    });
  }

  static ListingDisplaySettingsEntity _fromMap(Map<String, dynamic> data, Timestamp? updatedAt) {
    return ListingDisplaySettingsEntity(
      cityCode: data['cityCode'] as String? ?? '21',
      cityName: data['cityName'] as String? ?? 'Diyarbakır',
      districtCode: data['districtCode'] as String?,
      districtName: data['districtName'] as String?,
      companyName: data['companyName'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      updatedAt: updatedAt?.toDate(),
    );
  }

  static Future<void> set(ListingDisplaySettingsEntity s) async {
    await FirestoreService.ensureInitialized();
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colAppSettings)
        .doc(AppConstants.docListingDisplaySettings);
    await ref.set({
      'cityCode': s.cityCode,
      'cityName': s.cityName,
      'districtCode': s.districtCode,
      'districtName': s.districtName,
      'companyName': s.companyName,
      'logoUrl': s.logoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
