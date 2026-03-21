import 'dart:math' as math;

import 'models/rainbow_intel_models.dart';

/// Rainbow Investment Intelligence — skor motoru (saf Dart, Isolate uyumlu).
abstract final class RainbowScoreEngine {
  RainbowScoreEngine._();

  static const double _maxRoi = 35;
  static const double _maxDemand = 35;
  static const double _maxPrice = 30;

  /// Amortisman süresi (yıl): kira yoksa tahmini aylık kira = fiyat * 0.004.
  static double amortizationYears({
    required double priceTry,
    required double m2,
    double? monthlyRentTry,
  }) {
    final rent = monthlyRentTry ?? priceTry * 0.004;
    if (rent <= 0) return 99;
    final annual = rent * 12;
    if (annual <= 0) return 99;
    return priceTry / annual;
  }

  /// İlçe talep endeksi: 0–100 (Saha-Radar ile uyumlu — danışman yoğunluğu).
  static double districtDemandIndex({
    required int districtAgentCount,
    required int maxDistrictAgentCount,
  }) {
    if (maxDistrictAgentCount <= 0) return 50;
    return (districtAgentCount / maxDistrictAgentCount * 100)
        .clamp(0, 100)
        .toDouble();
  }

  static RainbowScoreResult compute(IntelIsolatePayload p) {
    final m2 = p.m2 <= 0 ? 1.0 : p.m2;
    final pricePerM2 = p.priceTry / m2;
    final avg = p.neighborhoodAvgPricePerM2 <= 0 ? pricePerM2 : p.neighborhoodAvgPricePerM2;
    final ratio = pricePerM2 / avg;

    final years = amortizationYears(
      priceTry: p.priceTry,
      m2: m2,
      monthlyRentTry: p.monthlyRentTry,
    );

    // ROI: kısa amortisman = yüksek puan (ör. 8 yıl → neredeyse max, 25 yıl → düşük).
    final roiNorm = math.exp(-years / 18).clamp(0.0, 1.0);
    final roiPts = roiNorm * _maxRoi;

    final demandRaw = districtDemandIndex(
      districtAgentCount: p.districtAgentCount,
      maxDistrictAgentCount: math.max(1, p.maxDistrictAgentCount),
    );
    final demandPts = (demandRaw / 100) * _maxDemand;

    // Fiyat/m² ortalamaya göre: ucuz = iyi (max 30 puan).
    double pricePts;
    if (ratio <= 0.85) {
      pricePts = _maxPrice;
    } else if (ratio <= 1.0) {
      pricePts = _maxPrice * (1.0 - (ratio - 0.85) / 0.15);
    } else if (ratio <= 1.2) {
      pricePts = _maxPrice * 0.35 * (1.0 - (ratio - 1.0) / 0.2);
    } else {
      pricePts = 0;
    }

    final breakdown = RainbowScoreBreakdown(
      roiComponent: roiPts.clamp(0, _maxRoi),
      demandComponent: demandPts.clamp(0, _maxDemand),
      pricePerM2Component: pricePts.clamp(0, _maxPrice),
      amortizationYears: years,
      districtDemandIndex: demandRaw,
      pricePerM2RatioVsNeighborhood: ratio,
    );

    final score = breakdown.total.clamp(0, 100).toDouble();
    return RainbowScoreResult(
      score0to100: score,
      breakdown: breakdown,
    );
  }

  /// 12 aylık fiyat eğrisi (tahmin / simülasyon) — API yokken deterministik dalga.
  static List<double> generatePriceTrend12m({
    required double basePricePerM2,
    required int seed,
  }) {
    final out = <double>[];
    final rnd = math.Random(seed);
    var v = basePricePerM2;
    for (var i = 0; i < 12; i++) {
      final w = (rnd.nextDouble() - 0.45) * 0.02;
      v *= 1 + w;
      out.add(v);
    }
    return out;
  }
}
