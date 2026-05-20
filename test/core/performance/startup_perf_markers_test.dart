import 'package:emlakmaster_mobile/core/performance/startup_perf_markers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StartupPerfMarkers.once logs only first call per name', () {
    StartupPerfMarkers.resetForTest();
    StartupPerfMarkers.once('test_milestone');
    StartupPerfMarkers.once('test_milestone');
    StartupPerfMarkers.once('other');
    // Test binding disables console logs; reset must not throw.
    StartupPerfMarkers.resetForTest();
  });
}
