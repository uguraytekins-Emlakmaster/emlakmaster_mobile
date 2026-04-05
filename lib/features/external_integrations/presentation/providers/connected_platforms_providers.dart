import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/platform_setup_merge.dart';
import '../../data/connected_platforms_mock.dart';
import '../../data/platform_setup_firestore_repository.dart';
import '../../domain/admin_platform_connection_row.dart';
import '../../domain/integration_platform.dart';
import '../../domain/integration_platform_id.dart';
import '../../domain/platform_connection_ui_state.dart';
import '../../domain/platform_setup_record.dart';

final platformSetupRepositoryProvider = Provider<PlatformSetupFirestoreRepository>((ref) {
  return PlatformSetupFirestoreRepository();
});

/// Firestore `offices/{officeId}/platform_setups/*` — canlı akış.
final platformSetupMapProvider =
    StreamProvider.autoDispose.family<Map<IntegrationPlatformId, PlatformSetupRecord>, String>(
  (ref, officeId) {
    if (officeId.isEmpty) {
      return Stream.value(<IntegrationPlatformId, PlatformSetupRecord>{});
    }
    return ref.read(platformSetupRepositoryProvider).watchMap(officeId);
  },
);

String _resolvedOfficeIdForIntegrations(Ref ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  final officeFromMem = ref.watch(primaryMembershipProvider).valueOrNull?.officeId;
  final officeFromDoc =
      uid.isEmpty ? null : ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId;
  return (officeFromMem != null && officeFromMem.isNotEmpty)
      ? officeFromMem
      : (officeFromDoc ?? '');
}

/// Mock tanım + ofis kurulum kaydı birleşimi (dürüst kart durumu).
final platformListProvider = Provider<List<IntegrationPlatform>>((ref) {
  ref.watch(currentUserProvider);
  ref.watch(primaryMembershipProvider);

  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  final officeId = _resolvedOfficeIdForIntegrations(ref);

  final asyncMap = ref.watch(platformSetupMapProvider(officeId));
  final records = asyncMap.when(
    data: (m) => m,
    loading: () => <IntegrationPlatformId, PlatformSetupRecord>{},
    error: (_, __) => <IntegrationPlatformId, PlatformSetupRecord>{},
  );

  final base = ConnectedPlatformsMock.userPlatforms();
  if (uid.isEmpty) {
    return base;
  }
  return base
      .map(
        (p) => mergePlatformWithSetup(
          base: p,
          record: records[p.id],
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
