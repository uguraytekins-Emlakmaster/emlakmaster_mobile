import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ownedListingRowsStaleCacheProvider =
    NotifierProvider.autoDispose<OwnedListingRowsStaleCache, List<ListingRowView>?>(
  OwnedListingRowsStaleCache.new,
);

class OwnedListingRowsStaleCache
    extends AutoDisposeNotifier<List<ListingRowView>?> {
  @override
  List<ListingRowView>? build() {
    ref.listen(ownedListingRowsProvider, (_, next) {
      next.whenData((rows) => state = rows);
    });
    return null;
  }
}

final ownedListingRowsDisplayProvider =
    Provider.autoDispose<AsyncValue<List<ListingRowView>>>((ref) {
  final streamAsync = ref.watch(ownedListingRowsProvider);
  final stale = ref.watch(ownedListingRowsStaleCacheProvider);
  return streamAsync.when(
    data: (rows) => AsyncData(rows),
    loading: () => stale != null
        ? AsyncData(stale)
        : const AsyncLoading(),
    error: (e, st) => stale != null
        ? AsyncData(stale)
        : AsyncError(e, st),
  );
});
