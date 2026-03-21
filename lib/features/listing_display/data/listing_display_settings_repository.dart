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
      // Firestore’da cityCode bazen sayı (21) — harici ilan sorgusu string ile eşleşmeli.
      cityCode: _asStringCode(data['cityCode']),
      cityName: (data['cityName'] as String?)?.trim().isNotEmpty == true
          ? (data['cityName'] as String).trim()
          : 'Diyarbakır',
      districtCode: (data['districtCode'] as String?)?.trim(),
      districtName: (data['districtName'] as String?)?.trim(),
      companyName: data['companyName'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      updatedAt: updatedAt?.toDate(),
    );
  }

  static String _asStringCode(dynamic v) {
    if (v == null) return '21';
    if (v is int) return v.toString();
    if (v is double) return v.round().toString();
    if (v is num) return v.round().toString();
    final s = v.toString().trim();
    return s.isEmpty ? '21' : s;
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
