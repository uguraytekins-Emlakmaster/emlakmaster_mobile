import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/connected_platforms_mock.dart';
import '../../domain/admin_platform_connection_row.dart';
import '../../domain/integration_platform.dart';
import '../../domain/integration_platform_id.dart';
import '../../domain/platform_connection_ui_state.dart';

/// Tüm platform satırları (mock). İleride repository ile değiştirilir.
final platformListProvider = Provider<List<IntegrationPlatform>>((ref) {
  return ConnectedPlatformsMock.userPlatforms();
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
