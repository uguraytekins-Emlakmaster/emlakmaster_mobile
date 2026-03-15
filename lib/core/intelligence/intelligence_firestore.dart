import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';

/// Intelligence skorları Firestore'a yazma / okuma. UI sadece bu hazır veriyi okur.
class IntelligenceFirestore {
  /// listing_metrics/{listingId} – momentum, price position, velocity.
  static Future<void> setListingScores(ListingIntelligenceScores scores) async {
    await FirestoreService.ensureInitialized();
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colListingMetrics)
        .doc(scores.listingId);
    await ref.set({
      'listingId': scores.listingId,
      'momentumScore': scores.momentumScore,
      'momentumSignal': scores.momentumSignal.id,
      'pricingPositionScore': scores.pricingPositionScore,
      'pricingPosition': scores.pricingPosition.id,
      'velocityScore': scores.velocityScore,
      'regionDemandScore': scores.regionDemandScore,
      'computedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> listingScoresStream(String listingId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.colListingMetrics)
        .doc(listingId)
        .snapshots();
  }

  /// analytics_daily – bugünün keşifleri, market pulse, daily brief.
  static Future<void> setDailyDiscovery(List<DealDiscoveryItem> items) async {
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
            'computedAt': e.computedAt != null ? Timestamp.fromDate(e.computedAt!) : null,
          }).toList(),
      'computedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setMarketHeatmap(List<RegionHeatmapScore> heatmap) async {
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
    }, SetOptions(merge: true));
  }

  static Future<void> setDailyBrief(List<DailyBriefItem> items) async {
    await FirestoreService.ensureInitialized();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colAnalyticsDaily)
        .doc('brief_$date');
    await ref.set({
      'date': date,
      'items': items.map((e) => {
            'id': e.id,
            'category': e.category,
            'title': e.title,
            'subtitle': e.subtitle,
            'priority': e.priority,
            'computedAt': e.computedAt != null ? Timestamp.fromDate(e.computedAt!) : null,
          }).toList(),
      'computedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setMissedOpportunities(List<MissedOpportunityItem> items) async {
    await FirestoreService.ensureInitialized();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colAnalyticsDaily)
        .doc('missed_$date');
    await ref.set({
      'date': date,
      'items': items.map((e) => {
            'id': e.id,
            'customerId': e.customerId,
            'reason': e.reason,
            'score': e.score,
            'computedAt': e.computedAt != null ? Timestamp.fromDate(e.computedAt!) : null,
          }).toList(),
      'computedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream: bugünün keşifleri (eşik uygulanmış liste UI'da yapılır).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> discoveryStream() {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return FirebaseFirestore.instance
        .collection(AppConstants.colAnalyticsDaily)
        .doc('discovery_$date')
        .snapshots();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> heatmapStream() {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return FirebaseFirestore.instance
        .collection(AppConstants.colAnalyticsDaily)
        .doc('heatmap_$date')
        .snapshots();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> dailyBriefStream() {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return FirebaseFirestore.instance
        .collection(AppConstants.colAnalyticsDaily)
        .doc('brief_$date')
        .snapshots();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> missedOpportunitiesStream() {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return FirebaseFirestore.instance
        .collection(AppConstants.colAnalyticsDaily)
        .doc('missed_$date')
        .snapshots();
  }
}
