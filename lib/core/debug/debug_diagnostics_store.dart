import 'package:flutter/foundation.dart';

import '../config/dev_mode_config.dart';

/// Test sırasında son API hatasını tutar (UI debug paneli).
final class DebugDiagnosticsStore extends ChangeNotifier {
  DebugDiagnosticsStore._();
  static final DebugDiagnosticsStore instance = DebugDiagnosticsStore._();

  String? _lastApiError;
  DateTime? _lastApiErrorAt;

  String? get lastApiError => _lastApiError;

  DateTime? get lastApiErrorAt => _lastApiErrorAt;

  /// [traceHttpCall] ve benzeri yollardan çağrılır.
  void recordApiError(String label, Object error, [StackTrace? stackTrace]) {
    if (kReleaseMode || !isDevMode) return;
    final b = StringBuffer()
      ..writeln('[$label]')
      ..writeln(error.toString());
    if (stackTrace != null) {
      final lines = stackTrace.toString().split('\n');
      b.writeln(lines.take(6).join('\n'));
    }
    _lastApiError = b.toString().trim();
    _lastApiErrorAt = DateTime.now();
    notifyListeners();
  }

  void clearLastApiError() {
    if (kReleaseMode || !isDevMode) return;
    _lastApiError = null;
    _lastApiErrorAt = null;
    notifyListeners();
  }
}
