import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';

/// Shell sekmesi / ağır ekran ilk içerik süresi (ms).
void logShellScreenReady({
  required String screenName,
  required int elapsedMs,
  int? itemCount,
}) {
  AnalyticsService.instance.logEvent(
    AnalyticsEvents.screenContentReady,
    {
      AnalyticsEvents.paramScreen: screenName,
      AnalyticsEvents.paramDurationMs: elapsedMs,
      if (itemCount != null) AnalyticsEvents.paramCount: itemCount,
    },
  );
}
