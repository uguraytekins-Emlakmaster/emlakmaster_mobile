import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:flutter/foundation.dart';

/// Shell sekmesi / ağır ekran ilk içerik süresi (ms).
void logShellScreenReady({
  required String screenName,
  required int elapsedMs,
  int? itemCount,
}) {
  const capture = bool.fromEnvironment('CAPTURE_STARTUP_PERF');
  final countSuffix = itemCount != null ? ' items=$itemCount' : '';
  final line =
      '[Perf] screen_content_ready screen=$screenName ${elapsedMs}ms$countSuffix';
  if (capture) {
    // ignore: avoid_print
    print(line);
  } else if (kDebugMode || kProfileMode) {
    AppLogger.d(line);
  }
  AnalyticsService.instance.logEvent(
    AnalyticsEvents.screenContentReady,
    {
      AnalyticsEvents.paramScreen: screenName,
      AnalyticsEvents.paramDurationMs: elapsedMs,
      if (itemCount != null) AnalyticsEvents.paramCount: itemCount,
    },
  );
}
