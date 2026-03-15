import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../logging/app_logger.dart';
import 'retry_policy.dart';
import 'sync_status.dart';

/// Firestore veya diğer kritik işlemleri retry ile çalıştırır; başarıda sync durumunu günceller.
/// Uzun ömürlü ve kendini onaran davranış için tüm yazma işlemlerinde kullanılabilir.
Future<T> runWithResilience<T>(
  Future<T> Function() action, {
  required Ref<Object?> ref,
  void Function(T result)? onSuccess,
}) async {
  final result = await RetryPolicy.run(action, onRetry: (attempt, e, st) {
    AppLogger.w('Resilience retry $attempt', e, st);
  });
  ref.read(syncStatusProvider.notifier).recordSyncSuccess();
  onSuccess?.call(result);
  return result;
}
