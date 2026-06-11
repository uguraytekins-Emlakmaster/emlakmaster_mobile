import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';

/// Intelligence skorları Firestore'a yazma / okuma. UI sadece bu hazır veriyi okur.
class IntelligenceFirestore {
  /// analytics_daily – bugünün keşifleri ve bölgesel ısı haritası.
  /// [rollupSource]: örn. [AppConstants.clientRollupSourceValue] (Spark istemci rollup).
  static Future<void> setDailyDiscovery(List<DealDiscoveryItem> items, {String? rollupSource}) async {
    await FirestoreService.ensureInitialized();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colAnalyticsDaily)
        .doc('discovery_$date');
    await ref.set({
      'date': date,
      'items': items.map((e) => {
            'id': e.id,
            'type': e.type,
            'listingId': e.listingId,
            'customerId': e.customerId,
            'title': e.title,
            'subtitle': e.subtitle,
            'score': e.score,
            'highlights': e.highlights,
            'computedAt': e.computedAt != null ? Timestamp.fromDate(e.computedAt!) : null,
          }).toList(),
      'computedAt': FieldValue.serverTimestamp(),
      if (rollupSource != null) 'source': rollupSource,
    }, SetOptions(merge: true));
  }

  static Future<void> setMarketHeatmap(List<RegionHeatmapScore> heatmap, {String? rollupSource}) async {
    await FirestoreService.ensureInitialized();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colAnalyticsDaily)
        .doc('heatmap_$date');
    await ref.set({
      'date': date,
      'regions': heatmap.map((e) => {
            'regionId': e.regionId,
            'regionName': e.regionName,
            'demandScore': e.demandScore,
            'budgetSegment': e.budgetSegment,
            'propertyTypeHint': e.propertyTypeHint,
            'computedAt': e.computedAt != null ? Timestamp.fromDate(e.computedAt!) : null,
          }).toList(),
      'computedAt': FieldValue.serverTimestamp(),
      if (rollupSource != null) 'source': rollupSource,
    }, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> heatmapStream() {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return FirebaseFirestore.instance
        .collection(AppConstants.colAnalyticsDaily)
        .doc('heatmap_$date')
        .snapshots();
  }

}
