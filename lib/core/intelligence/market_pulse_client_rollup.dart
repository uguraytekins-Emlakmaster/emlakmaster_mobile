import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_firestore.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Blaze / Cloud Functions olmadan (Spark): [external_listings] üzerinden heatmap + fırsat keşfi yazar.
/// Kurallar: `source == client_rollup_v1` ile sınırlı güvenli yazım.
abstract final class MarketPulseClientRollupService {
  MarketPulseClientRollupService._();

  static const _regionOrder = ['kayapinar', 'baglar', 'yenisehir'];

  static const _regionMeta = <String, ({String name, String budget, String hint})>{
    'kayapinar': (name: 'Kayapınar', budget: '4M-6M', hint: '3+1'),
    'baglar': (name: 'Bağlar', budget: '2M-4M', hint: 'arsa'),
    'yenisehir': (name: 'Yenişehir', budget: '3M-5M', hint: '2+1'),
  };

  /// İlçe / metin → bölge id (Diyarbakır).
  @visibleForTesting
  static String inferRegionId(String? districtName) {
    if (districtName == null || districtName.trim().isEmpty) return 'yenisehir';
    final n = districtName
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a');
    if (n.contains('kayapinar') || n.contains('kayapınar')) return 'kayapinar';
    if (n.contains('baglar') || n.contains('bağlar')) return 'baglar';
    if (n.contains('yenisehir') || n.contains('yenişehir')) return 'yenisehir';
    return 'yenisehir';
  }

  @visibleForTesting
  static double median(List<double> nums) {
    if (nums.isEmpty) return 0;
    final s = List<double>.from(nums)..sort();
    final m = s.length ~/ 2;
    if (s.length.isOdd) return s[m];
    return (s[m - 1] + s[m]) / 2;
  }

  /// [force]: true → throttle yok (ör. ilan senkronu sonrası).
  static Future<MarketPulseRollupOutcome> runNow({
    required String cityCode,
    bool force = false,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return const MarketPulseRollupOutcome.skipped('no_user');
    }
    await FirestoreService.ensureInitialized();

    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(AppConstants.keyMarketPulseClientRollupLastMs);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (last != null &&
          now - last < AppConstants.marketPulseClientRollupMinInterval.inMilliseconds) {
        return const MarketPulseRollupOutcome.skipped('throttled');
      }
    }

    final ratio = await _loadOpportunityRatio();
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.colExternalListings)
        .where('cityCode', isEqualTo: cityCode)
        .limit(500)
        .get();

    final byRegion = <String, List<double>>{
      'kayapinar': [],
      'baglar': [],
      'yenisehir': [],
    };
    final rows = <_ListingRow>[];

    for (final doc in snap.docs) {
      final x = doc.data();
      final pv = (x['priceValue'] as num?)?.toDouble();
      if (pv == null || pv <= 0) continue;
      final district = x['districtName'] as String?;
      final rid = inferRegionId(district);
      byRegion[rid]!.add(pv);
      rows.add(
        _ListingRow(
          docId: doc.id,
          title: x['title'] as String? ?? 'İlan',
          priceValue: pv,
          regionId: rid,
        ),
      );
    }

    final nowDt = DateTime.now();

    final heatmap = _regionOrder.map((rid) {
      final prices = byRegion[rid] ?? [];
      final n = prices.length;
      final demandScore = n == 0 ? 0.58 : (0.55 + (n.clamp(0, 80) / 200)).clamp(0.0, 0.92);
      final meta = _regionMeta[rid]!;
      return RegionHeatmapScore(
        regionId: rid,
        regionName: meta.name,
        demandScore: demandScore,
        budgetSegment: meta.budget,
        propertyTypeHint: meta.hint,
        computedAt: nowDt,
      );
    }).toList();

    final discoveryItems = <DealDiscoveryItem>[];
    final dateStr = nowDt.toIso8601String().substring(0, 10);

    for (final rid in _regionOrder) {
      final prices = byRegion[rid] ?? [];
      if (prices.length < 3) continue;
      final med = median(prices);
      if (med <= 0) continue;
      final threshold = med * ratio;
      for (final row in rows) {
        if (row.regionId != rid) continue;
        if (row.priceValue >= threshold) continue;
        final raw = 0.8 + (1 - row.priceValue / med) * 0.35;
        final score = raw.clamp(0.8, 0.98);
        final meta = _regionMeta[rid]!;
        discoveryItems.add(
          DealDiscoveryItem(
            id: 'opp_${row.docId}_$dateStr',
            listingId: row.docId,
            title: row.title,
            subtitle: '${meta.name}: medyan ~${med.round()} ₺ altı',
            score: score,
            computedAt: nowDt,
            highlights: const [
              'Medyanın altında (istemci rollup)',
              'Spark — Cloud Functions gerekmez',
            ],
          ),
        );
      }
    }

    discoveryItems.sort((a, b) => b.score.compareTo(a.score));
    final top = discoveryItems.take(25).toList();

    await IntelligenceFirestore.setMarketHeatmap(
      heatmap,
      rollupSource: AppConstants.clientRollupSourceValue,
    );
    await IntelligenceFirestore.setDailyDiscovery(
      top,
      rollupSource: AppConstants.clientRollupSourceValue,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.keyMarketPulseClientRollupLastMs,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (kDebugMode) {
      debugPrint(
        '[MarketPulseClientRollup] city=$cityCode listings=${snap.size} opportunities=${top.length}',
      );
    }

    return MarketPulseRollupOutcome(
      listingSampleSize: snap.size,
      opportunityCount: top.length,
    );
  }

  /// Ayarlardan şehir kodu ile çalıştırır (throttle uygulanır).
  static Future<MarketPulseRollupOutcome> runThrottledForCurrentSettings({
    required String cityCode,
  }) {
    return runNow(cityCode: cityCode);
  }

  static Future<double> _loadOpportunityRatio() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colAppSettings)
          .doc(AppConstants.docIntelligencePipeline)
          .get();
      final v = snap.data()?['opportunityPriceRatio'];
      if (v is num) {
        return v.toDouble().clamp(0.5, 0.99);
      }
    } catch (_) {}
    return 0.85;
  }
}

class _ListingRow {
  const _ListingRow({
    required this.docId,
    required this.title,
    required this.priceValue,
    required this.regionId,
  });

  final String docId;
  final String title;
  final double priceValue;
  final String regionId;
}

class MarketPulseRollupOutcome {
  const MarketPulseRollupOutcome({
    required this.listingSampleSize,
    required this.opportunityCount,
    this.skipReason,
  });

  const MarketPulseRollupOutcome.skipped(String reason)
      : listingSampleSize = 0,
        opportunityCount = 0,
        skipReason = reason;

  final int listingSampleSize;
  final int opportunityCount;
  final String? skipReason;

  bool get didSkip => skipReason != null;
}
