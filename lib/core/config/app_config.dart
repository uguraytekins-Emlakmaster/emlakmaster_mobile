import 'package:flutter/foundation.dart';

/// Uygulama yapılandırması. Ortam (env) ile değiştirilebilir.
abstract final class AppConfig {
  static const bool isProduction = kReleaseMode;
  static const bool enableLogging = kDebugMode;
}
