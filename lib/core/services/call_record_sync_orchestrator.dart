import 'dart:async';

import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:emlakmaster_mobile/features/calls/services/call_record_sync_service.dart';

/// Uygulama açılışı, bağlantı, periyodik zamanlayıcı ve öne gelince yerel çağrı senkronu.
class CallRecordSyncOrchestrator {
  CallRecordSyncOrchestrator._();
  static final CallRecordSyncOrchestrator instance = CallRecordSyncOrchestrator._();

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(CallRecordSyncService.syncForCurrentUser());
    });
    SyncManager.onlineStreamDebounced.listen((online) {
      if (online) {
        unawaited(CallRecordSyncService.syncForCurrentUser());
      }
    });
    AppLifecyclePowerService.onAppResumed.listen((_) {
      unawaited(CallRecordSyncService.syncForCurrentUser());
    });
    unawaited(CallRecordSyncService.syncForCurrentUser());
  }
}
