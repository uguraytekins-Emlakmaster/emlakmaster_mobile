import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/intelligence/region_heatmap_defaults.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Takip edilen bölge id (SharedPreferences).
final favoriteInvestRegionIdProvider = FutureProvider<String>((ref) async {
  return SettingsService.instance.getFavoriteInvestRegionId();
});

/// Kişiselleştirilmiş "Fırsat Endeksi" özeti — ısı haritası + tercih edilen ilçe.
/// Ağ/Firestore hata verirse varsayılan Diyarbakır üçlüsüyle hesaplanır (dashboard boş kalmaz).
/// Yenileme sırasında önceki ısı haritası verisi korunur (titreme azaltılır).
final investmentOpportunitySummaryProvider =
    Provider<AsyncValue<InvestmentOpportunitySummary>>((ref) {
  final favAsync = ref.watch(favoriteInvestRegionIdProvider);
  final heatmapAsync = ref.watch(marketHeatmapProvider);

  return favAsync.when(
    data: (favId) => heatmapAsync.when(
      data: (regions) {
        final list =
            regions.isEmpty ? marketPulseDefaultRegionScores : regions;
        return AsyncValue.data(_summaryForFavorite(favId, list));
      },
      loading: () {
        final snapshot = heatmapAsync.valueOrNull;
        if (snapshot != null) {
          final list = snapshot.isEmpty
              ? marketPulseDefaultRegionScores
              : snapshot;
          return AsyncValue.data(_summaryForFavorite(favId, list));
        }
        return const AsyncValue.loading();
      },
      error: (e, st) {
        if (kDebugMode) {
          debugPrint(
            '[FırsatEndeksi] heatmap hata, varsayılan bölgeler kullanılıyor: $e',
          );
        }
        return AsyncValue.data(
          _summaryForFavorite(favId, marketPulseDefaultRegionScores),
        );
      },
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// [regions] boş olmamalı; yine de boşsa güvenli varsayılan.
InvestmentOpportunitySummary _summaryForFavorite(
  String favId,
  List<RegionHeatmapScore> regions,
) {
  final safe = regions.isEmpty ? marketPulseDefaultRegionScores : regions;
  RegionHeatmapScore? match;
  for (final r in safe) {
    if (r.regionId == favId) {
      match = r;
      break;
    }
  }
  final r = match ?? safe.first;
  return InvestmentOpportunitySummary.fromRegion(r);
}

class InvestmentOpportunitySummary {
  const InvestmentOpportunitySummary({
    required this.regionLabel,
    required this.appetiteLabel,
    required this.demandScore,
  });

  final String regionLabel;
  final String appetiteLabel;
  final double demandScore;

  /// Firestore/ısı haritası yokken güvenli gösterim (Kayapınar varsayılan).
  factory InvestmentOpportunitySummary.fallback() =>
      InvestmentOpportunitySummary.fromRegion(marketPulseDefaultRegionScores.first);

  factory InvestmentOpportunitySummary.fromRegion(RegionHeatmapScore r) {
    final hint = (r.propertyTypeHint ?? '').trim();
    final segment = r.budgetSegment?.trim();
    final buf = StringBuffer(r.regionName.trim());
    if (hint.isNotEmpty) {
      buf.write(' $hint');
    } else if (segment != null && segment.isNotEmpty && segment != '—') {
      buf.write(' · $segment');
    }
    final appetite = _appetiteForDemand(r.demandScore);
    return InvestmentOpportunitySummary(
      regionLabel: buf.toString(),
      appetiteLabel: appetite,
      demandScore: r.demandScore,
    );
  }
}

String _appetiteForDemand(double d) {
  if (d >= 0.72) return 'Yüksek';
  if (d >= 0.52) return 'Orta';
  return 'Düşük';
}
