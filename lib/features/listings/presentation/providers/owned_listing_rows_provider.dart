import 'package:emlakmaster_mobile/core/services/listings_portfolio_stream.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ofis envanteri: canonical `listings` (ownerUserId / officeId) + `integration_listings` (dedup).
final ownedListingRowsProvider =
    StreamProvider.autoDispose<List<ListingRowView>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final uid = user?.uid ?? '';
  if (uid.isEmpty) {
    return Stream<List<ListingRowView>>.value(const []);
  }
  final officeId = ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId;
  return ListingsPortfolioStream.owned(uid: uid, officeId: officeId);
});
