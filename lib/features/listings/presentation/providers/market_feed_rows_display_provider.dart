import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/features/external_listings/presentation/providers/external_listings_provider.dart';
import 'package:emlakmaster_mobile/features/listings/data/listing_row_factory.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final marketFeedRowsStaleCacheProvider =
    NotifierProvider.autoDispose<MarketFeedRowsStaleCache, List<ListingRowView>?>(
  MarketFeedRowsStaleCache.new,
);

class MarketFeedRowsStaleCache extends AutoDisposeNotifier<List<ListingRowView>?> {
  @override
  List<ListingRowView>? build() {
    ref.listen(externalListingsStreamProvider, (_, next) {
      next.whenData(
        (list) => state = list.map(listingRowFromMarketFeed).toList(),
      );
    });
    return null;
  }
}

/// Pazar sekmesi — stale-while-revalidate.
final marketFeedRowsDisplayProvider =
    Provider.autoDispose<AsyncValue<List<ListingRowView>>>((ref) {
  final enabled = ref.watch(
    featureFlagsProvider.select(
      (a) => a.valueOrNull?[AppConstants.keyFeatureOfficialMarketFeed] ?? false,
    ),
  );
  if (!enabled) {
    return const AsyncValue.data(<ListingRowView>[]);
  }

  final streamAsync = ref.watch(externalListingsStreamProvider);
  final stale = ref.watch(marketFeedRowsStaleCacheProvider);
  return streamAsync.when(
    data: (list) => AsyncData(list.map(listingRowFromMarketFeed).toList()),
    loading: () => stale != null
        ? AsyncData(stale)
        : const AsyncLoading(),
    error: (e, st) => stale != null
        ? AsyncData(stale)
        : AsyncError(e, st),
  );
});
