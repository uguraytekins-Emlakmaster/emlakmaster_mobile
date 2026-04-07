import 'dart:async';

import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:emlakmaster_mobile/features/calls/services/call_record_sync_service.dart';

/// Uygulama açılışı, bağlantı, periyodik zamanlayıcı ve öne gelince yerel çağrı senkronu.
class CallRecordSyncOrchestrator {
  CallRecordSyncOrchestrator._();
  static final CallRecordSyncOrchestrator instance =
      CallRecordSyncOrchestrator._();

  bool _started = false;
  bool _syncInFlight = false;

  Future<void> _runSyncIfNeeded() async {
    if (_syncInFlight) return;
    if (AppLifecyclePowerService.isInBackground.value) return;
    _syncInFlight = true;
    try {
      await CallRecordSyncService.syncForCurrentUser();
    } finally {
      _syncInFlight = false;
    }
  }

  void start() {
    if (_started) return;
    _started = true;
    Future<void>.delayed(const Duration(seconds: 10), () {
      unawaited(_runSyncIfNeeded());
    });
    Timer.periodic(const Duration(minutes: 2), (_) {
      unawaited(_runSyncIfNeeded());
    });
    SyncManager.onlineStreamDebounced.listen((online) {
      if (online) {
        unawaited(_runSyncIfNeeded());
      }
    });
    AppLifecyclePowerService.onAppResumed.listen((_) {
      unawaited(_runSyncIfNeeded());
    });
  }
}
