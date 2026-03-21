import 'package:emlakmaster_mobile/features/analytics/domain/models/rainbow_intel_models.dart';
import 'package:emlakmaster_mobile/features/analytics/domain/rainbow_score_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compute returns score in 0–100', () {
    const p = IntelIsolatePayload(
      priceTry: 5000000,
      m2: 100,
      districtAgentCount: 5,
      maxDistrictAgentCount: 10,
      neighborhoodAvgPricePerM2: 45000,
      monthlyRentTry: 25000,
    );
    final r = RainbowScoreEngine.compute(p);
    expect(r.score0to100, greaterThanOrEqualTo(0));
    expect(r.score0to100, lessThanOrEqualTo(100));
    expect(r.breakdown.total, closeTo(r.score0to100, 0.01));
  });

  test('generatePriceTrend12m returns 12 points', () {
    final t = RainbowScoreEngine.generatePriceTrend12m(
      basePricePerM2: 50000,
      seed: 42,
    );
    expect(t.length, 12);
  });
}
