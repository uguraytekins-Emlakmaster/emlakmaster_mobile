import 'package:emlakmaster_mobile/core/deep_linking/region_insight_uri.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/intelligence/region_heatmap_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('regionInsightPathFromUri', () {
    test('https path', () {
      expect(
        regionInsightPathFromUri(Uri.parse('https://x.test/region-insight/kayapinar')),
        '/region-insight/kayapinar',
      );
    });

    test('emlakmaster triple slash', () {
      expect(
        regionInsightPathFromUri(Uri.parse('emlakmaster:///region-insight/kayapinar')),
        '/region-insight/kayapinar',
      );
    });

    test('emlakmaster host app', () {
      expect(
        regionInsightPathFromUri(Uri.parse('emlakmaster://app/region-insight/baglar')),
        '/region-insight/baglar',
      );
    });

    test('emlakmaster host region-insight', () {
      expect(
        regionInsightPathFromUri(Uri.parse('emlakmaster://region-insight/kayapinar')),
        '/region-insight/kayapinar',
      );
    });
  });

  group('resolveRegionHeatmapForRoute', () {
    test('deep link id only matches Kayapınar', () {
      final r = resolveRegionHeatmapForRoute(regionId: 'kayapinar');
      expect(r.regionName, 'Kayapınar');
      expect(r.budgetSegment, '4M-6M');
    });

    test('turkish ı in id still matches', () {
      final r = resolveRegionHeatmapForRoute(regionId: 'kayap%C4%B1nar');
      expect(r.regionName, 'Kayapınar');
    });

    test('extra wins over path', () {
      const custom = RegionHeatmapScore(
        regionId: 'kayapinar',
        regionName: 'Kayapınar',
        demandScore: 0.1,
        budgetSegment: 'X',
      );
      final r = resolveRegionHeatmapForRoute(regionId: 'yenisehir', extra: custom);
      expect(r.demandScore, 0.1);
      expect(r.budgetSegment, 'X');
    });
  });
}
