import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emlakmaster_mobile/core/intelligence/intelligence_firestore.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/intelligence/market_pulse_client_rollup.dart';
import 'package:emlakmaster_mobile/features/listing_display/data/listing_display_settings_repository.dart';

/// İlk okumada istemci rollup'ı tetikler; sonuçlar Firestore'dan okunur.
/// Kısa gecikme: ilk etkileşim tamamlanmadan ağır Firestore yazıları başlamasın.
/// Spark (Blaze yok): [MarketPulseClientRollupService] ile heatmap güncellenir (throttle'lı).
final intelligenceRunTriggerProvider = FutureProvider<void>((ref) async {
  await Future<void>.delayed(const Duration(seconds: 2));
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

/// Bölgesel talep ısı haritası (istemci rollup'ın external_listings'ten ürettiği gerçek veri).
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
