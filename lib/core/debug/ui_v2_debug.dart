import 'package:flutter/foundation.dart';

/// Debug-only build log for premium UI screens. Never shown in UI.
void logUiV2Active(String screenName, {String? detail}) {
  if (!kDebugMode) return;
  final extra = detail == null || detail.isEmpty ? '' : ' · $detail';
  debugPrint('[UI_V2_ACTIVE] $screenName build$extra');
}
