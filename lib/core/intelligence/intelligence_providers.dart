import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/intelligence/background_intelligence_service.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_firestore.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/intelligence/market_pulse_client_rollup.dart';
import 'package:emlakmaster_mobile/features/listing_display/data/listing_display_settings_repository.dart';

/// İlk okumada background servisi tetikler; sonuçlar Firestore'dan okunur.
/// Bir tick gecikme: ilk frame çizilsin, sonra ağır Firestore yazıları çalışsın (bellek/GPU baskısı azalır).
/// Spark (Blaze yok): [MarketPulseClientRollupService] ile heatmap/discovery güncellenir (throttle’lı).
final intelligenceRunTriggerProvider = FutureProvider<void>((ref) async {
  await Future<void>.delayed(Duration.zero);
  await BackgroundIntelligenceService.instance.runOnce();
  try {
    final settings = await ListingDisplaySettingsRepository.get();
    await MarketPulseClientRollupService.runThrottledForCurrentSettings(cityCode: settings.cityCode);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('intelligenceRunTriggerProvider: client rollup atlandı: $e');
      debugPrint(st.toString());
    }
  }
});

/// Bugün keşfedilen fırsatlar – sadece score >= opportunityRadarMinScore ana ekranda.
final discoveryItemsProvider = StreamProvider<List<DealDiscoveryItem>>((ref) {
  ref.watch(intelligenceRunTriggerProvider);
  return IntelligenceFirestore.discoveryStream().map((snap) {
    if (!snap.exists || snap.data() == null) return <DealDiscoveryItem>[];
    final list = snap.data()!['items'] as List<dynamic>? ?? [];
    final items = list.map((e) {
      if (e is! Map<String, dynamic>) return null;
      final computed = e['computedAt'] is Timestamp ? (e['computedAt'] as Timestamp).toDate() : null;
      final rawHighlights = e['highlights'];
      final highlights = rawHighlights is List
          ? rawHighlights.map((x) => x?.toString() ?? '').where((s) => s.isNotEmpty).toList()
          : const <String>[];
      return DealDiscoveryItem(
        id: e['id'] as String? ?? '',
        type: e['type'] as String? ?? 'hidden_opportunity',
        listingId: e['listingId'] as String?,
        customerId: e['customerId'] as String?,
        title: e['title'] as String?,
        subtitle: e['subtitle'] as String?,
        score: (e['score'] as num?)?.toDouble() ?? 0,
        computedAt: computed,
        highlights: highlights,
      );
    }).whereType<DealDiscoveryItem>().toList();
    return items.where((e) => e.score >= AppConstants.opportunityRadarMinScore).toList();
  });
});

/// Tüm keşifler (detay listesi; eşiksiz).
final discoveryItemsFullProvider = StreamProvider<List<DealDiscoveryItem>>((ref) {
  return IntelligenceFirestore.discoveryStream().map((snap) {
    if (!snap.exists || snap.data() == null) return <DealDiscoveryItem>[];
    final list = snap.data()!['items'] as List<dynamic>? ?? [];
    return list.map((e) {
      if (e is! Map<String, dynamic>) return null;
      final computed = e['computedAt'] is Timestamp ? (e['computedAt'] as Timestamp).toDate() : null;
      final rawHighlights = e['highlights'];
      final highlights = rawHighlights is List
          ? rawHighlights.map((x) => x?.toString() ?? '').where((s) => s.isNotEmpty).toList()
          : const <String>[];
      return DealDiscoveryItem(
        id: e['id'] as String? ?? '',
        type: e['type'] as String? ?? 'hidden_opportunity',
        listingId: e['listingId'] as String?,
        customerId: e['customerId'] as String?,
        title: e['title'] as String?,
        subtitle: e['subtitle'] as String?,
        score: (e['score'] as num?)?.toDouble() ?? 0,
        computedAt: computed,
        highlights: highlights,
      );
    }).whereType<DealDiscoveryItem>().toList();
  });
});

/// Market Pulse (bölgesel talep).
final marketHeatmapProvider = StreamProvider<List<RegionHeatmapScore>>((ref) {
  ref.watch(intelligenceRunTriggerProvider);
  return IntelligenceFirestore.heatmapStream().map((snap) {
    if (!snap.exists || snap.data() == null) return <RegionHeatmapScore>[];
    final list = snap.data()!['regions'] as List<dynamic>? ?? [];
    return list.map((e) {
      if (e is! Map<String, dynamic>) return null;
      final computed = e['computedAt'] is Timestamp ? (e['computedAt'] as Timestamp).toDate() : null;
      return RegionHeatmapScore(
        regionId: e['regionId'] as String? ?? '',
        regionName: e['regionName'] as String? ?? '',
        demandScore: (e['demandScore'] as num?)?.toDouble() ?? 0,
        budgetSegment: e['budgetSegment'] as String?,
        propertyTypeHint: e['propertyTypeHint'] as String?,
        computedAt: computed,
      );
    }).whereType<RegionHeatmapScore>().toList();
  });
});

/// AI Daily Brief.
final dailyBriefProvider = StreamProvider<List<DailyBriefItem>>((ref) {
  ref.watch(intelligenceRunTriggerProvider);
  return IntelligenceFirestore.dailyBriefStream().map((snap) {
    if (!snap.exists || snap.data() == null) return <DailyBriefItem>[];
    final list = snap.data()!['items'] as List<dynamic>? ?? [];
    return list.map((e) {
      if (e is! Map<String, dynamic>) return null;
      final computed = e['computedAt'] is Timestamp ? (e['computedAt'] as Timestamp).toDate() : null;
      return DailyBriefItem(
        id: e['id'] as String? ?? '',
        category: e['category'] as String?,
        title: e['title'] as String?,
        subtitle: e['subtitle'] as String?,
        priority: e['priority'] as int? ?? 0,
        computedAt: computed,
      );
    }).whereType<DailyBriefItem>().toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  });
});

/// Missed Opportunities.
final missedOpportunitiesProvider = StreamProvider<List<MissedOpportunityItem>>((ref) {
  ref.watch(intelligenceRunTriggerProvider);
  return IntelligenceFirestore.missedOpportunitiesStream().map((snap) {
    if (!snap.exists || snap.data() == null) return <MissedOpportunityItem>[];
    final list = snap.data()!['items'] as List<dynamic>? ?? [];
    return list.map((e) {
      if (e is! Map<String, dynamic>) return null;
      final computed = e['computedAt'] is Timestamp ? (e['computedAt'] as Timestamp).toDate() : null;
      return MissedOpportunityItem(
        id: e['id'] as String? ?? '',
        customerId: e['customerId'] as String?,
        reason: e['reason'] as String?,
        score: (e['score'] as num?)?.toDouble() ?? 0,
        computedAt: computed,
      );
    }).whereType<MissedOpportunityItem>().toList();
  });
});

/// Tek ilan için skorlar (UI sadece okur).
final listingScoresProvider = StreamProvider.family<ListingIntelligenceScores?, String>((ref, listingId) {
  return IntelligenceFirestore.listingScoresStream(listingId).map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    final d = snap.data()!;
    final computed = d['computedAt'] is Timestamp ? (d['computedAt'] as Timestamp).toDate() : null;
    MomentumSignal signal = MomentumSignal.stable;
    for (final s in MomentumSignal.values) {
      if (s.id == d['momentumSignal']) { signal = s; break; }
    }
    PricingPosition pos = PricingPosition.normal;
    for (final p in PricingPosition.values) {
      if (p.id == d['pricingPosition']) { pos = p; break; }
    }
    return ListingIntelligenceScores(
      listingId: listingId,
      momentumScore: (d['momentumScore'] as num?)?.toDouble() ?? 0,
      momentumSignal: signal,
      pricingPositionScore: (d['pricingPositionScore'] as num?)?.toDouble() ?? 0,
      pricingPosition: pos,
      velocityScore: (d['velocityScore'] as num?)?.toDouble() ?? 0,
      regionDemandScore: (d['regionDemandScore'] as num?)?.toDouble() ?? 0,
      computedAt: computed,
    );
  });
});
