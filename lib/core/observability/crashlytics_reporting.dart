import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Üretimde kritik olmayan hataları Crashlytics'e düşürür (flush, senkron vb.).
abstract final class CrashlyticsReporting {
  CrashlyticsReporting._();

  static void recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) {
    if (kDebugMode) return;
    if (Firebase.apps.isEmpty) return;
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
      );
    } catch (_) {}
  }
}
