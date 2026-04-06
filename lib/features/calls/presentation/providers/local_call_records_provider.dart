import 'dart:async';

import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/call_local_hive_store.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/services/call_record_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hive’daki yerel çağrı kayıtları (senkron göstergesi için); periyodik yenileme.
///
/// Performans: 5 sn aralık + veri parmak izi aynıysa yayın atlama; dakikada bir
/// zorunlu yayın (zaman tabanlı senkron riski / `now` tüketicileri için).
final localCallRecordsStreamProvider =
    StreamProvider.autoDispose<List<LocalCallRecord>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value([]);
  }

  final controller = StreamController<List<LocalCallRecord>>();
  Timer? timer;
  var lastFingerprint = 0;
  var periodicTick = 0;

  int fingerprint(List<LocalCallRecord> list) {
    var h = list.length;
    for (final r in list) {
      h = Object.hash(
        h,
        r.id,
        r.isSynced,
        r.lastSyncAt,
        r.syncAttemptCount,
        r.nextRetryAtMs,
        r.syncFailedPermanent,
        r.pendingCapturePatchJson?.length ?? 0,
      );
    }
    return h;
  }

  Future<void> emit({required bool force}) async {
    try {
      await CallLocalHiveStore.instance.ensureInit();
      if (controller.isClosed) return;
      final list = await CallLocalHiveStore.instance.listAllForAgent(uid);
      final fp = fingerprint(list);
      if (!force && fp == lastFingerprint) return;
      lastFingerprint = fp;
      if (!controller.isClosed) controller.add(list);
    } catch (_) {}
  }

  unawaited(emit(force: true));
  timer = Timer.periodic(const Duration(seconds: 5), (_) {
    periodicTick++;
    final forceMinutePulse = periodicTick % 12 == 0;
    unawaited(emit(force: forceMinutePulse));
  });

  ref.onDispose(() {
    timer?.cancel();
    unawaited(controller.close());
  });

  return controller.stream;
});

/// Kalıcı başarısız kayıtta manuel yeniden dene.
Future<void> retryLocalCallRecordSync(LocalCallRecord r) async {
  await CallLocalHiveStore.instance.resetPermanentForManualRetry(
    agentId: r.agentId,
    localId: r.id,
  );
  await CallRecordSyncService.syncForCurrentUser();
}
