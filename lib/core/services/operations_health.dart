import 'package:flutter/foundation.dart';

/// Self-healing operations: retry queue, failure counters, stale indicator (placeholder-ready).
class OperationsHealth {
  OperationsHealth._();
  static final OperationsHealth instance = OperationsHealth._();

  int _writeFailureCount = 0;
  int get writeFailureCount => _writeFailureCount;

  void incrementWriteFailure() {
    _writeFailureCount++;
    if (kDebugMode) debugPrint('OperationsHealth: writeFailureCount=$_writeFailureCount');
  }

  void resetWriteFailureCount() {
    _writeFailureCount = 0;
  }

  /// Offline write queue length (placeholder: SyncManager + Firestore persistence handle offline).
  int get offlineQueueLength => 0;

  /// Stale data: son senkronizasyon zamanı (placeholder).
  DateTime? get lastSyncAt => null;

  bool get hasStaleData => false;
}
