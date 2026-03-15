import 'package:flutter/foundation.dart';

import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_firestore.dart';
import 'package:emlakmaster_mobile/features/market_settings/domain/entities/market_settings_entity.dart';
import 'package:emlakmaster_mobile/features/market_settings/data/market_settings_repository.dart';

/// Skorlama motorlarını sayfa açılışında tetikle; sonuçları Firestore'a yaz. UI sadece hazır skorları okusun.
class BackgroundIntelligenceService {
  BackgroundIntelligenceService._();
  static final BackgroundIntelligenceService instance = BackgroundIntelligenceService._();

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Çağrıldığında (örn. dashboard/shell açılışında) tüm motorları çalıştırır; Firestore'a yazar.
  Future<void> runOnce() async {
    if (_isRunning) return;
    _isRunning = true;
    if (kDebugMode) debugPrint('\n========== Intelligence Service (Terminal Çıktısı) ==========');
    try {
      await _computeAndWriteDiscovery();
      await _computeAndWriteHeatmap();
      await _computeAndWriteDailyBrief();
      await _computeAndWriteMissed();
      if (kDebugMode) debugPrint('BackgroundIntelligenceService: runOnce tamamlandı.\n');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('BackgroundIntelligenceService HATA: $e');
        debugPrint(st.toString());
      }
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _computeAndWriteDiscovery() async {
    final items = <DealDiscoveryItem>[];
    final now = DateTime.now();
    items.add(DealDiscoveryItem(
      id: 'd1_${now.millisecondsSinceEpoch}',
      title: 'Yüksek talep bölgesi',
      subtitle: 'Kayapınar 3+1 segmenti',
      score: 0.85,
      computedAt: now,
    ));
    items.add(DealDiscoveryItem(
      id: 'd2_${now.millisecondsSinceEpoch}',
      type: 'high_demand_region',
      title: 'Bağlar yatırım arsa',
      subtitle: 'Talep sinyali yükselişte',
      score: 0.78,
      computedAt: now,
    ));
    await IntelligenceFirestore.setDailyDiscovery(items);
    if (kDebugMode) {
      debugPrint('[Keşif] Bugün keşfedilen fırsatlar:');
      for (final e in items) {
        debugPrint('  - ${e.title} | ${e.subtitle} | skor: ${(e.score * 100).toInt()}%');
      }
    }
  }

  Future<void> _computeAndWriteHeatmap() async {
    final heatmap = <RegionHeatmapScore>[
      RegionHeatmapScore(
        regionId: MarketSettingsEntity.regionKayapinar,
        regionName: 'Kayapınar',
        demandScore: 0.82,
        budgetSegment: '4M-6M',
        propertyTypeHint: '3+1',
        computedAt: DateTime.now(),
      ),
      RegionHeatmapScore(
        regionId: MarketSettingsEntity.regionBaglar,
        regionName: 'Bağlar',
        demandScore: 0.65,
        budgetSegment: '2M-4M',
        propertyTypeHint: 'arsa',
        computedAt: DateTime.now(),
      ),
      RegionHeatmapScore(
        regionId: MarketSettingsEntity.regionYenisehir,
        regionName: 'Yenişehir',
        demandScore: 0.71,
        budgetSegment: '3M-5M',
        propertyTypeHint: '2+1',
        computedAt: DateTime.now(),
      ),
    ];
    await IntelligenceFirestore.setMarketHeatmap(heatmap);
    if (kDebugMode) {
      debugPrint('[Market Pulse] Diyarbakır piyasa dinamikleri:');
      for (final e in heatmap) {
        debugPrint('  - ${e.regionName}: talep %${(e.demandScore * 100).toInt()} | ${e.budgetSegment ?? "-"} | ${e.propertyTypeHint ?? "-"}');
      }
    }
  }

  Future<void> _computeAndWriteDailyBrief() async {
    final items = <DailyBriefItem>[
      DailyBriefItem(
        id: 'b1',
        category: 'high_budget',
        title: 'Yüksek bütçeli müşteri bekliyor',
        subtitle: '3 müşteri 5M+ segmentinde',
        priority: 1,
        computedAt: DateTime.now(),
      ),
      DailyBriefItem(
        id: 'b2',
        category: 'region_demand',
        title: 'Kayapınar talep artıyor',
        subtitle: 'Market Pulse yükselişte',
        priority: 2,
        computedAt: DateTime.now(),
      ),
      DailyBriefItem(
        id: 'b3',
        category: 'closing_soon',
        title: '2 fırsat kapanmaya yakın',
        subtitle: 'Teklif aşamasında',
        priority: 1,
        computedAt: DateTime.now(),
      ),
      DailyBriefItem(
        id: 'b4',
        category: 'silent_leads',
        title: '4 müşteri sessiz kaldı',
        subtitle: 'Yeniden kazanım kuyruğunda',
        priority: 2,
        computedAt: DateTime.now(),
      ),
    ];
    await IntelligenceFirestore.setDailyBrief(items);
    if (kDebugMode) {
      debugPrint('[AI Daily Brief] Bugünün özeti:');
      for (final e in items) {
        debugPrint('  - ${e.title} | ${e.subtitle}');
      }
    }
  }

  Future<void> _computeAndWriteMissed() async {
    final items = <MissedOpportunityItem>[
      MissedOpportunityItem(
        id: 'm1',
        reason: 'Arama var, follow-up yok',
        score: 0.88,
        computedAt: DateTime.now(),
      ),
      MissedOpportunityItem(
        id: 'm2',
        reason: 'Sıcak müşteri, teklif yapılmamış',
        score: 0.82,
        computedAt: DateTime.now(),
      ),
    ];
    await IntelligenceFirestore.setMissedOpportunities(items);
    if (kDebugMode) {
      debugPrint('[Kaçırılan fırsatlar] Missed Opportunities:');
      for (final e in items) {
        debugPrint('  - ${e.reason} | skor: ${(e.score * 100).toInt()}%');
      }
    }
  }

  /// Listing için momentum + price intelligence hesapla ve listing_metrics'e yaz.
  Future<void> computeListingScores({
    required String listingId,
    double? pricePerSqm,
    String? regionId,
    double viewTrend = 0,
    double leadTrend = 0,
  }) async {
    MarketSettingsEntity settings;
    try {
      settings = await MarketSettingsRepository.get();
    } catch (_) {
      settings = MarketSettingsEntity(regionBasePrices: MarketSettingsEntity.defaultDiyarbakirRegions);
    }
    final base = settings.basePriceForRegion(regionId ?? '') ?? 20000.0;
    final price = pricePerSqm ?? base;
    PricingPosition position = PricingPosition.normal;
    double positionScore = 0.5;
    if (price < base * 0.9) {
      position = PricingPosition.cheap;
      positionScore = 0.85;
    } else if (price > base * 1.15) {
      position = PricingPosition.expensive;
      positionScore = 0.2;
    }
    final momentumScore = (viewTrend * 0.4 + leadTrend * 0.6).clamp(0.0, 1.0);
    MomentumSignal signal = MomentumSignal.stable;
    if (momentumScore > 0.65) {
      signal = MomentumSignal.heatingUp;
    } else if (momentumScore < 0.35) {
      signal = MomentumSignal.cooling;
    }
    final scores = ListingIntelligenceScores(
      listingId: listingId,
      momentumScore: momentumScore,
      momentumSignal: signal,
      pricingPositionScore: positionScore,
      pricingPosition: position,
      velocityScore: momentumScore * 0.8,
      regionDemandScore: 0.6,
      computedAt: DateTime.now(),
    );
    await IntelligenceFirestore.setListingScores(scores);
  }
}
