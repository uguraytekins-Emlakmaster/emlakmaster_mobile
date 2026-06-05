import 'dart:async';

import 'package:flutter/foundation.dart';

/// Geçici çıkış akışı teşhisi — debug/profile. Release'te no-op.
abstract final class LogoutFlowTracer {
  static DateTime? _t0;
  static int _n = 0;
  static bool _active = false;

  static bool get isActive => _active && kDebugMode;

  static void begin(String source) {
    if (!kDebugMode) return;
    _t0 = DateTime.now();
    _n = 0;
    _active = true;
    _emit('LOGOUT_FLOW', 'BEGIN source=$source');
  }

  static void step(String tag, [String detail = '']) {
    if (!kDebugMode || !_active) return;
    _n++;
    final ms = DateTime.now().difference(_t0!).inMilliseconds;
    debugPrint(
      '[$tag] +${ms}ms #$_n${detail.isEmpty ? '' : ' $detail'}',
    );
  }

  static void end([String detail = 'ok']) {
    if (!kDebugMode || !_active) return;
    step('LOGOUT_FLOW', 'END $detail');
    _active = false;
    _t0 = null;
  }

  static void fail(Object e, [StackTrace? st]) {
    if (!kDebugMode) return;
    step('LOGOUT_FLOW', 'FAIL $e');
    if (st != null) debugPrint('$st');
    _active = false;
    _t0 = null;
  }

  /// 1s üzeri await'leri işaretle.
  static Future<T> watch<T>(String label, Future<T> future) async {
    if (!kDebugMode || !_active) return future;
    final sw = Stopwatch()..start();
    try {
      return await future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          step('LOGOUT_FLOW', 'STALL timeout label=$label elapsed=${sw.elapsedMilliseconds}ms');
          throw TimeoutException('LogoutFlowTracer stall: $label');
        },
      );
    } finally {
      if (sw.elapsedMilliseconds > 1000) {
        step('LOGOUT_FLOW', 'SLOW label=$label elapsed=${sw.elapsedMilliseconds}ms');
      }
    }
  }

  static void _emit(String tag, String msg) {
    debugPrint('[$tag] $msg');
  }
}
