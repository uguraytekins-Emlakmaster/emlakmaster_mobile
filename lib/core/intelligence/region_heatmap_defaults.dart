import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/features/market_settings/domain/entities/market_settings_entity.dart';

/// Firestore / arka plan henüz veri üretmediyse gösterilecek varsayılan Diyarbakır üçlüsü
/// ([BackgroundIntelligenceService._computeAndWriteHeatmap] ile uyumlu).
List<RegionHeatmapScore> get marketPulseDefaultRegionScores => const [
      RegionHeatmapScore(
        regionId: MarketSettingsEntity.regionKayapinar,
        regionName: 'Kayapınar',
        demandScore: 0.82,
        budgetSegment: '4M-6M',
        propertyTypeHint: '3+1',
      ),
      RegionHeatmapScore(
        regionId: MarketSettingsEntity.regionBaglar,
        regionName: 'Bağlar',
        demandScore: 0.65,
        budgetSegment: '2M-4M',
        propertyTypeHint: 'arsa',
      ),
      RegionHeatmapScore(
        regionId: MarketSettingsEntity.regionYenisehir,
        regionName: 'Yenişehir',
        demandScore: 0.71,
        budgetSegment: '3M-5M',
        propertyTypeHint: '2+1',
      ),
    ];

/// Route `extra` veya `regionId` ile [RegionHeatmapScore] çözümler (Market Pulse → detay).
/// Derin link `/region-insight/kayapinar` (extra yok) ile de varsayılan üçlüden eşleşir.
RegionHeatmapScore resolveRegionHeatmapForRoute({
  required String regionId,
  Object? extra,
}) {
  if (extra is RegionHeatmapScore) {
    return extra;
  }
  final decoded = Uri.decodeComponent(regionId);
  final key = _normalizeRegionKey(decoded);
  for (final r in marketPulseDefaultRegionScores) {
    if (_normalizeRegionKey(r.regionId) == key) return r;
    if (_normalizeRegionKey(r.regionName) == key) return r;
  }
  return RegionHeatmapScore(
    regionId: decoded,
    regionName: _humanizeRegionId(decoded),
    demandScore: 0.55,
  );
}

/// Karşılaştırma: ASCII küçük harf + Türkçe harfleri Latin eşdeğerine indirgeme.
String _normalizeRegionKey(String raw) {
  final s = raw.trim().toLowerCase();
  const tr = 'ığüşöç';
  const en = 'igusoc';
  final buf = StringBuffer();
  for (final c in s.runes) {
    final ch = String.fromCharCode(c);
    final i = tr.indexOf(ch);
    buf.write(i >= 0 ? en[i] : ch);
  }
  return buf.toString();
}

String _humanizeRegionId(String id) {
  if (id.isEmpty) return 'Bölge';
  final s = id.replaceAll('_', ' ').replaceAll('-', ' ');
  return s.split(' ').map((w) {
    if (w.isEmpty) return w;
    return '${w[0].toUpperCase()}${w.substring(1)}';
  }).join(' ');
}
