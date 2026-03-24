import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Merkezi logger. Production'da hassas veri loglanmaz; Crashlytics ile entegre edilebilir.
final class AppLogger {
  AppLogger._();

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

  /// Yönlendirme / navigator (yalnızca debug/profile).
  static void nav(String message) {
    if (kReleaseMode) return;
    _logger.d('[nav] $message');
  }

  /// Riverpod / durum (yalnızca debug/profile).
  static void state(String message) {
    if (kReleaseMode) return;
    _logger.d('[state] $message');
  }

  /// HTTP / harici API (yalnızca debug/profile; URL veya gövde loglamayın).
  static void api(String message) {
    if (kReleaseMode) return;
    _logger.d('[api] $message');
  }
}
