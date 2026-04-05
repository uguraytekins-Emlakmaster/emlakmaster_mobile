import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/platform_setup_merge.dart';
import '../../data/connected_platforms_mock.dart';
import '../../data/platform_setup_memory_store.dart';
import '../../domain/admin_platform_connection_row.dart';
import '../../domain/integration_platform.dart';
import '../../domain/integration_platform_id.dart';
import '../../domain/platform_connection_ui_state.dart';

/// Yerel kurulum kaydı değişince liste yenilenir.
final platformSetupRevisionProvider = StateProvider<int>((ref) => 0);

/// Mock tanım + ofis kurulum kaydı birleşimi (dürüst kart durumu).
final platformListProvider = Provider<List<IntegrationPlatform>>((ref) {
  ref.watch(platformSetupRevisionProvider);
  ref.watch(currentUserProvider);
  ref.watch(primaryMembershipProvider);

  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  final officeFromMem = ref.watch(primaryMembershipProvider).valueOrNull?.officeId;
  final officeFromDoc =
      uid.isEmpty ? null : ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId;
  final officeId = (officeFromMem != null && officeFromMem.isNotEmpty)
      ? officeFromMem
      : (officeFromDoc ?? '');

  final store = PlatformSetupMemoryStore.instance;
  final base = ConnectedPlatformsMock.userPlatforms();
  if (uid.isEmpty) {
    return base;
  }
  return base
      .map(
        (p) => mergePlatformWithSetup(
          base: p,
          record: store.get(uid, officeId, p.id),
        ),
      )
      .toList();
});

/// Tek platform — [platformListProvider] üzerinden türetilir (çift sorgu yok).
final platformConnectionProvider =
    Provider.family<IntegrationPlatform?, IntegrationPlatformId>((ref, id) {
  for (final p in ref.watch(platformListProvider)) {
    if (p.id == id) return p;
  }
  return null;
});

/// Bağlantı durumu chip’i için kısayol.
final platformStatusProvider =
    Provider.family<PlatformConnectionUiState, IntegrationPlatformId>((ref, id) {
  return ref.watch(platformConnectionProvider(id))?.connectionState ??
      PlatformConnectionUiState.disconnected;
});

/// Ofis yöneticisi — bağlantı özeti (mock). Gerçek veri: office + members join.
final adminPlatformConnectionsProvider =
    Provider<List<AdminPlatformConnectionRow>>((ref) {
  return ConnectedPlatformsMock.officeOverview();
});
