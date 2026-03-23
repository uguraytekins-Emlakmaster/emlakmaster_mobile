import 'package:emlakmaster_mobile/core/intelligence/market_pulse_client_rollup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarketPulseClientRollupService', () {
    test('median', () {
      expect(MarketPulseClientRollupService.median([1, 2, 3, 4, 5]), closeTo(3, 1e-9));
      expect(MarketPulseClientRollupService.median([1, 2, 3, 4]), closeTo(2.5, 1e-9));
    });

    test('inferRegionId', () {
      expect(MarketPulseClientRollupService.inferRegionId('Kayapınar'), 'kayapinar');
      expect(MarketPulseClientRollupService.inferRegionId('Bağlar'), 'baglar');
      expect(MarketPulseClientRollupService.inferRegionId('Yenişehir'), 'yenisehir');
      expect(MarketPulseClientRollupService.inferRegionId(null), 'yenisehir');
    });
  });
}
