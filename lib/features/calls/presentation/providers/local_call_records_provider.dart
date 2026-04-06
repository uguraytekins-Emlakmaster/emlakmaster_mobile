import 'dart:async';

import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/call_local_hive_store.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/services/call_record_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hive’daki yerel çağrı kayıtları (senkron göstergesi için); periyodik yenileme.
final localCallRecordsStreamProvider =
    StreamProvider.autoDispose<List<LocalCallRecord>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value([]);
  }

  final controller = StreamController<List<LocalCallRecord>>();
  Timer? timer;

  Future<void> emit() async {
    try {
      await CallLocalHiveStore.instance.ensureInit();
      if (!controller.isClosed) {
        controller.add(await CallLocalHiveStore.instance.listAllForAgent(uid));
      }
    } catch (_) {}
  }

  unawaited(emit());
  timer = Timer.periodic(const Duration(seconds: 2), (_) => emit());

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
