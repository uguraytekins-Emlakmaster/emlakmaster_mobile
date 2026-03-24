import 'package:flutter/foundation.dart';

import '../config/dev_mode_config.dart';
import '../logging/app_logger.dart';
import 'debug_diagnostics_store.dart';

/// Debug modunda HTTP çağrılarının süresini ve hatalarını loglar; release'te doğrudan [fn] çalışır.
Future<T> traceHttpCall<T>(String label, Future<T> Function() fn) async {
  if (!kDebugMode) return fn();
  final sw = Stopwatch()..start();
  try {
    final r = await fn();
    AppLogger.api('$label · ${sw.elapsedMilliseconds}ms');
    return r;
  } catch (e, st) {
    AppLogger.e('[API] $label', e, st);
    if (!kReleaseMode && isDevMode) {
      DebugDiagnosticsStore.instance.recordApiError(label, e, st);
    }
    rethrow;
  }
}
