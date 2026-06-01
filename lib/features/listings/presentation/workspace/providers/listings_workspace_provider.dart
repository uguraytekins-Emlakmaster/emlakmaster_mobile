import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_display_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Portföyüm workspace — tek türetilmiş snapshot.
/// Mevcut [ownedListingRowsDisplayProvider] yeniden kullanılır.
final listingsWorkspaceSnapshotProvider =
    Provider.autoDispose<AsyncValue<ListingsWorkspaceSnapshot>>((ref) {
  final rowsAsync = ref.watch(ownedListingRowsDisplayProvider);
  final canManage = ref.watch(canManagePlatformIntegrationsProvider);

  return rowsAsync.when(
    data: (rows) => AsyncValue.data(
      computeListingsWorkspaceSnapshot(
        rows,
        now: DateTime.now(),
        canManage: canManage,
      ),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
