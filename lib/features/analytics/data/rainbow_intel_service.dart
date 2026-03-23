import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/intelligence/region_heatmap_defaults.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';

import '../domain/models/rainbow_intel_models.dart';
import '../domain/rainbow_score_engine.dart';
import 'external_market_api_placeholder.dart';
import 'intel_report_history_repository.dart';
import 'rainbow_intel_cache.dart';

/// Hibrit veri: Firestore + önbellek + dış API yer tutucu.
class RainbowIntelService {
  RainbowIntelService({
    IntelReportHistoryRepository? historyRepository,
  }) : _history = historyRepository ?? IntelReportHistoryRepository();

  final IntelReportHistoryRepository _history;

  IntelReportHistoryRepository get history => _history;

  static Future<Map<String, int>> _districtAgentCounts() async {
    await FirestoreService.ensureInitialized();
    final map = <String, int>{};
    try {
      final snap =
          await FirebaseFirestore.instance.collection('agents').get();
      for (final d in snap.docs) {
        final dist = d.data()['locationDistrict'] as String? ?? '';
        if (dist.isEmpty) continue;
        map[dist] = (map[dist] ?? 0) + 1;
      }
    } catch (_) {
      // offline / kural
    }
    return map;
  }

  static int _maxCount(Map<String, int> m) {
    if (m.isEmpty) return 1;
    return m.values.reduce((a, b) => a > b ? a : b);
  }

  Future<IntelIsolatePayload> buildPayloadFromListing({
    required String listingId,
    double? monthlyRentTry,
  }) async {
    await FirestoreService.ensureInitialized();
    final doc =
        await FirebaseFirestore.instance.collection('listings').doc(listingId).get();
    if (!doc.exists) {
      throw StateError('İlan bulunamadı');
    }
    final d = doc.data() ?? {};
    final priceRaw = d['price'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw?.toString() ?? '') ?? 0;
    final m2raw = d['m2'] ?? d['area'];
    final m2 = m2raw is num ? m2raw.toDouble() : double.tryParse('$m2raw') ?? 0;
    final district =
        d['district'] as String? ?? d['location'] as String? ?? 'Genel';

    final ext = await ExternalMarketApiPlaceholder.fetchDistrictSnapshot(district);
    var avg = await RainbowIntelCache.avgPricePerM2ForDistrict(district);
    if (ext.avgPricePerM2District != null) {
      avg = ext.avgPricePerM2District!;
    }

    final counts = await _districtAgentCounts();
    final dc = counts[district] ?? 0;
    final mx = _maxCount(counts);

    return IntelIsolatePayload(
      priceTry: price,
      m2: m2 <= 0 ? 1 : m2,
      districtAgentCount: dc,
      maxDistrictAgentCount: mx,
      neighborhoodAvgPricePerM2: avg,
      monthlyRentTry: monthlyRentTry,
    );
  }

  Future<IntelIsolatePayload> buildPayloadCustom(CustomIntelInput input) async {
    final district = input.district.trim().isEmpty ? 'Genel' : input.district;
    final ext = await ExternalMarketApiPlaceholder.fetchDistrictSnapshot(district);
    var avg = await RainbowIntelCache.avgPricePerM2ForDistrict(district);
    if (ext.avgPricePerM2District != null) {
      avg = ext.avgPricePerM2District!;
    }
    final counts = await _districtAgentCounts();
    final dc = counts[district] ?? 0;
    final mx = _maxCount(counts);

    return IntelIsolatePayload(
      priceTry: input.priceTry,
      m2: input.m2 <= 0 ? 1 : input.m2,
      districtAgentCount: dc,
      maxDistrictAgentCount: mx,
      neighborhoodAvgPricePerM2: avg,
      monthlyRentTry: input.monthlyRentTry,
    );
  }

  Future<RainbowScoreResult> computeInIsolate(IntelIsolatePayload payload) {
    return Isolate.run(() => RainbowScoreEngine.compute(payload));
  }

  Future<RainbowIntelReport> buildFullReport({
    required IntelIsolatePayload payload,
    required RainbowScoreResult score,
    required String propertyTitle,
    required String district,
    required String listingUrl,
    String? listingId,
    String? imageUrl,
  }) async {
    final id = _history.newId();
    final m2 = payload.m2;
    final trend = RainbowScoreEngine.generatePriceTrend12m(
      basePricePerM2: payload.priceTry / m2,
      seed: id.hashCode,
    );
    final districtSnapshots = await _loadDistrictSnapshotsKayapinarBaglar();
    return RainbowIntelReport(
      id: id,
      generatedAt: DateTime.now(),
      listingId: listingId,
      propertyTitle: propertyTitle,
      district: district,
      listingPriceTry: payload.priceTry,
      m2: m2,
      rainbowScore: score.score0to100,
      breakdown: score.breakdown,
      priceTrend12mTryPerM2: trend,
      listingUrl: listingUrl,
      imageUrl: imageUrl,
      districtSnapshots: districtSnapshots,
    );
  }

  /// Canlı heatmap (bugün) veya varsayılan Diyarbakır bölgeleri — PDF grid.
  static Future<List<DistrictSnapshotRow>> _loadDistrictSnapshotsKayapinarBaglar() async {
    try {
      await FirestoreService.ensureInitialized();
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colAnalyticsDaily)
          .doc('heatmap_$date')
          .get();
      final raw = snap.data()?['regions'] as List<dynamic>?;
      if (raw != null && raw.isNotEmpty) {
        final out = <DistrictSnapshotRow>[];
        for (final e in raw) {
          if (e is! Map<String, dynamic>) continue;
          final id = e['regionId'] as String? ?? '';
          if (id != 'kayapinar' && id != 'baglar') continue;
          out.add(
            DistrictSnapshotRow(
              districtName: e['regionName'] as String? ?? '',
              demandScore: (e['demandScore'] as num?)?.toDouble() ?? 0,
              budgetSegment: e['budgetSegment'] as String? ?? '',
              propertyTypeHint: e['propertyTypeHint'] as String?,
            ),
          );
        }
        if (out.length >= 2) return out;
      }
    } catch (_) {}
    return marketPulseDefaultRegionScores
        .where((r) => r.regionId == 'kayapinar' || r.regionId == 'baglar')
        .map(
          (r) => DistrictSnapshotRow(
            districtName: r.regionName,
            demandScore: r.demandScore,
            budgetSegment: r.budgetSegment ?? '',
            propertyTypeHint: r.propertyTypeHint,
          ),
        )
        .toList();
  }

  Future<void> persistReport(RainbowIntelReport r) => _history.save(r);
}
