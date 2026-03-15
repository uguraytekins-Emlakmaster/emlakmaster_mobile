import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

/// Kendini onaran işlemler için yeniden deneme politikası.
/// Geçici hatalarda exponential backoff ile tekrar dener; kalıcı hatalarda vazgeçer.
class RetryPolicy {
  RetryPolicy._();

  static const int defaultMaxRetries = AppConstants.maxRetries;
  static const Duration defaultInitialDelay = AppConstants.retryDelay;

  /// [action]'ı en fazla [maxRetries] kez dener. Başarısız olursa son exception'ı fırlatır.
  /// [onRetry] (isteğe bağlı) her denemeden önce çağrılır (log/UI için).
  static Future<T> run<T>(
    Future<T> Function() action, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    void Function(int attempt, Object error, StackTrace? st)? onRetry,
    bool Function(Object error)? isRetryable,
  }) async {
    assert(maxRetries >= 1);
    int attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (e, st) {
        attempt++;
        final retryable = isRetryable?.call(e) ?? _defaultRetryable(e);
        if (attempt >= maxRetries || !retryable) {
          AppLogger.e('RetryPolicy', e, st);
          rethrow;
        }
        final delay = initialDelay * (1 << (attempt - 1));
        if (kDebugMode) {
          debugPrint('RetryPolicy: attempt $attempt/$maxRetries after ${delay.inMilliseconds}ms');
        }
        onRetry?.call(attempt, e, st);
        await Future<void>.delayed(delay);
      }
    }
  }

  static bool _defaultRetryable(Object error) {
    final s = error.toString().toLowerCase();
    if (s.contains('permission-denied') || s.contains('not-found')) return false;
    if (s.contains('network') || s.contains('unavailable') || s.contains('timeout')) return true;
    if (s.contains('canceled') || s.contains('cancelled')) return false;
    return true;
  }
}
