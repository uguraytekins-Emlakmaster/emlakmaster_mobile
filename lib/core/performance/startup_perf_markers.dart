import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Soğuk açılış kilometre taşları — debug ve **profile** modda konsola yazılır.
///
/// Terminal filtresi: `[Perf] startup_milestone`
abstract final class StartupPerfMarkers {
  StartupPerfMarkers._();

  static final Stopwatch _sw = Stopwatch()..start();
  static final Set<String> _seen = {};

  /// `flutter test --dart-define=CAPTURE_STARTUP_PERF=true` ile otomatik baseline.
  static const bool _captureMode = bool.fromEnvironment('CAPTURE_STARTUP_PERF');

  static bool get _logsEnabled =>
      _captureMode || ((kDebugMode || kProfileMode) && !_isFlutterTest);

  static bool get _isFlutterTest {
    if (_captureMode) return false;
    try {
      final name = WidgetsBinding.instance.runtimeType.toString();
      return name.contains('TestWidgetsFlutterBinding') ||
          name.contains('AutomatedTestWidgetsFlutterBinding') ||
          name.contains('LiveTestWidgetsFlutterBinding');
    } catch (_) {
      return true;
    }
  }

  /// Tek seferlik kilometre taşı (tekrar çağrılırsa yok sayılır).
  static void once(String name) {
    if (!_logsEnabled || _seen.contains(name)) return;
    _seen.add(name);
    _log(name);
  }

  /// Her çağrıda süreyi yazar (ör. sekme geçişi denemeleri için değil; nadiren).
  static void mark(String name) {
    if (!_logsEnabled) return;
    _log(name);
  }

  static void _log(String name) {
    final elapsedMs = _sw.elapsedMilliseconds;
    final line =
        '[Perf] startup_milestone name=$name elapsed_ms=$elapsedMs';
    if (_captureMode) {
      // ignore: avoid_print
      print(line);
    } else {
      debugPrint(line);
    }
    if (kReleaseMode || kProfileMode) {
      AnalyticsService.instance.logEvent(
        AnalyticsEvents.startupMilestone,
        {
          AnalyticsEvents.paramMilestone: name,
          AnalyticsEvents.paramDurationMs: elapsedMs,
        },
      );
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _seen.clear();
    _sw
      ..reset()
      ..start();
  }
}
