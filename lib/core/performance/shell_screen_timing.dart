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
  if (kDebugMode) {
    final countSuffix = itemCount != null ? ' items=$itemCount' : '';
    AppLogger.d(
      '[Perf] screen_content_ready screen=$screenName ${elapsedMs}ms$countSuffix',
    );
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
