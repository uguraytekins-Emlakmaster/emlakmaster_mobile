import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Takiplerim workspace — tek türetilmiş snapshot.
/// Mevcut [resurrectionQueueProvider] yeniden kullanılır; yeni backend yok.
final followUpWorkspaceSnapshotProvider =
    Provider.autoDispose<AsyncValue<FollowUpWorkspaceSnapshot>>((ref) {
  final queueAsync = ref.watch(resurrectionQueueProvider);

  return queueAsync.when(
    data: (items) => AsyncValue.data(
      computeFollowUpWorkspaceSnapshot(items, now: DateTime.now()),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
