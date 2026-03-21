import 'package:emlakmaster_mobile/core/services/finance_rates_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('eurTryFromUsdBaseRates', () {
    test('TRY 34 / EUR 0.92 ≈ EUR/TRY 36.96', () {
      final v = eurTryFromUsdBaseRates(34.0, 0.92);
      expect(v, closeTo(34.0 / 0.92, 0.0001));
    });

    test('eurPerUsd sıfıra yakınsa 0 döner', () {
      expect(eurTryFromUsdBaseRates(34, 0), 0);
      expect(eurTryFromUsdBaseRates(34, 1e-12), 0);
    });
  });
}
