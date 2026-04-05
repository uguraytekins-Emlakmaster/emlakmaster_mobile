import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/features/external_listings/presentation/providers/external_listings_provider.dart';
import 'package:emlakmaster_mobile/features/listings/data/listing_row_factory.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pazar akışı — yalnızca [keyFeatureOfficialMarketFeed] açıkken [external_listings] ingest.
final marketFeedRowsProvider = Provider<AsyncValue<List<ListingRowView>>>((ref) {
  final enabled = ref.watch(
    featureFlagsProvider.select(
      (a) => a.valueOrNull?[AppConstants.keyFeatureOfficialMarketFeed] ?? false,
    ),
  );
  if (!enabled) {
    return const AsyncValue.data(<ListingRowView>[]);
  }
  final async = ref.watch(externalListingsStreamProvider);
  return async.when(
    data: (list) => AsyncValue.data(list.map(listingRowFromMarketFeed).toList()),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
