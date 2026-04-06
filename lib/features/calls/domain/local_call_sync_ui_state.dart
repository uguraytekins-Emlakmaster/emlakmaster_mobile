import 'package:emlakmaster_mobile/features/calls/data/call_record_sync_constants.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';

/// Çağrı satırı senkron göstergesi (Hive + zaman).
enum LocalCallSyncUiState {
  pending,
  syncing,
  synced,
  failedRetry,
  failedPermanent,
}

/// [LocalCallRecord] → UI durumu (ikon/renk).
LocalCallSyncUiState deriveLocalCallSyncUiState(
  LocalCallRecord r, {
  required int nowMs,
}) {
  if (r.syncFailedPermanent ||
      (!r.isSynced && nowMs > r.createdAt + CallRecordSyncConstants.maxRetryWindowMs)) {
    return LocalCallSyncUiState.failedPermanent;
  }
  if (r.isSyncing) {
    return LocalCallSyncUiState.syncing;
  }
  if (r.pendingCapturePatchJson != null && r.pendingCapturePatchJson!.trim().isNotEmpty) {
    return LocalCallSyncUiState.pending;
  }
  if (r.isSynced) {
    return LocalCallSyncUiState.synced;
  }
  if (r.nextRetryAtMs != null && nowMs < r.nextRetryAtMs!) {
    return LocalCallSyncUiState.failedRetry;
  }
  return LocalCallSyncUiState.pending;
}
