import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/market_settings/domain/entities/market_settings_entity.dart';

/// Market Settings okuma/yazma (Diyarbakır baz m2; Price Intelligence).
class MarketSettingsRepository {
  static Future<MarketSettingsEntity> get() async {
    await FirestoreService.ensureInitialized();
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colAppSettings)
        .doc(AppConstants.docMarketSettings);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      return MarketSettingsEntity(
        regionBasePrices: MarketSettingsEntity.defaultDiyarbakirRegions,
        updatedAt: DateTime.now(),
      );
    }
    final data = snap.data()!;
    final list = data['regionBasePrices'] as List<dynamic>?;
    final regions = <RegionBasePrice>[];
    if (list != null) {
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          final updated = e['updatedAt'] is Timestamp ? (e['updatedAt'] as Timestamp).toDate() : null;
          regions.add(RegionBasePrice(
            regionId: e['regionId'] as String? ?? '',
            regionName: e['regionName'] as String? ?? '',
            basePricePerSqm: (e['basePricePerSqm'] as num?)?.toDouble() ?? 0,
            currency: e['currency'] as String? ?? 'TRY',
            updatedAt: updated,
          ));
        }
      }
    }
    if (regions.isEmpty) {
      return MarketSettingsEntity(
        regionBasePrices: MarketSettingsEntity.defaultDiyarbakirRegions,
        updatedAt: DateTime.now(),
      );
    }
    final updatedAt = data['updatedAt'] is Timestamp
        ? (data['updatedAt'] as Timestamp).toDate()
        : null;
    return MarketSettingsEntity(
      regionBasePrices: regions,
      currency: data['currency'] as String? ?? 'TRY',
      updatedAt: updatedAt,
    );
  }

  static Stream<MarketSettingsEntity> stream() async* {
    await FirestoreService.ensureInitialized();
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colAppSettings)
        .doc(AppConstants.docMarketSettings)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) {
        return MarketSettingsEntity(
          regionBasePrices: MarketSettingsEntity.defaultDiyarbakirRegions,
          updatedAt: DateTime.now(),
        );
      }
      final data = snap.data()!;
      final list = data['regionBasePrices'] as List<dynamic>?;
      final regions = <RegionBasePrice>[];
      if (list != null) {
        for (final e in list) {
          if (e is Map<String, dynamic>) {
            final updated = e['updatedAt'] is Timestamp ? (e['updatedAt'] as Timestamp).toDate() : null;
            regions.add(RegionBasePrice(
              regionId: e['regionId'] as String? ?? '',
              regionName: e['regionName'] as String? ?? '',
              basePricePerSqm: (e['basePricePerSqm'] as num?)?.toDouble() ?? 0,
              currency: e['currency'] as String? ?? 'TRY',
              updatedAt: updated,
            ));
          }
        }
      }
      if (regions.isEmpty) {
        return MarketSettingsEntity(
          regionBasePrices: MarketSettingsEntity.defaultDiyarbakirRegions,
          updatedAt: DateTime.now(),
        );
      }
      final updatedAt = data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null;
      return MarketSettingsEntity(
        regionBasePrices: regions,
        currency: data['currency'] as String? ?? 'TRY',
        updatedAt: updatedAt,
      );
    });
  }

  static Future<void> set(MarketSettingsEntity settings) async {
    await FirestoreService.ensureInitialized();
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colAppSettings)
        .doc(AppConstants.docMarketSettings);
    await ref.set({
      'regionBasePrices': settings.regionBasePrices
          .map((r) => {
                'regionId': r.regionId,
                'regionName': r.regionName,
                'basePricePerSqm': r.basePricePerSqm,
                'currency': r.currency,
                if (r.updatedAt != null) 'updatedAt': Timestamp.fromDate(r.updatedAt!),
              })
          .toList(),
      'currency': settings.currency,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
