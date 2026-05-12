import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Merkezi logger. Production'da hassas veri loglanmaz; Crashlytics ile entegre edilebilir.
final class AppLogger {
  AppLogger._();

  /// Ayrıntılı state/nav/api teşhisleri debug'ta bile varsayılan olarak kapalı.
  /// Gerektiğinde `--dart-define=EM_VERBOSE_DEBUG_LOGS=true` ile açılabilir.
  static const bool _verboseDebugLogs =
      bool.fromEnvironment('EM_VERBOSE_DEBUG_LOGS');

  static bool get verboseDiagnosticsEnabled =>
      !kReleaseMode && _verboseDebugLogs;

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 4,
      lineLength: 80,
      printEmojis: false,
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Kayıt akışı teşhisi (release’te de warning seviyesinde görünür; PII yazmayın).
  static void forensic(String message) {
    if (!verboseDiagnosticsEnabled) return;
    _logger.w('[forensic] $message');
  }

  /// Yönlendirme / navigator (yalnızca debug/profile).
  static void nav(String message) {
    if (!verboseDiagnosticsEnabled) return;
    _logger.d('[nav] $message');
  }

  /// Riverpod / durum (yalnızca debug/profile).
  static void state(String message) {
    if (!verboseDiagnosticsEnabled) return;
    _logger.d('[state] $message');
  }

  /// HTTP / harici API (yalnızca debug/profile; URL veya gövde loglamayın).
  static void api(String message) {
    if (!verboseDiagnosticsEnabled) return;
    _logger.d('[api] $message');
  }
}
