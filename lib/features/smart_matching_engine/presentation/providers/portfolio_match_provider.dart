import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/smart_matching_engine/data/listing_for_match.dart';
import 'package:emlakmaster_mobile/features/smart_matching_engine/domain/usecases/compute_top_matched_listings_isolate.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Listings stream → List<ListingForMatch> (AI portföy eşleştirme için).
final listingsForMatchStreamProvider = StreamProvider<List<ListingForMatch>>((ref) {
  return FirestoreService.listingsStream().map((snap) {
    return snap.docs.map((d) => ListingForMatch.fromMap(d.id, d.data())).toList();
  });
});

/// Müşteri için en uygun ilanlar (skor sıralı, en fazla 6). Hesaplama isolate'te (UI thread serbest).
final topMatchedListingsForCustomerProvider =
    FutureProvider.family<List<MatchedListingDisplay>, String>((ref, customerId) async {
  final customer = await ref.watch(customerEntityByIdProvider(customerId).future);
  if (customer == null) return [];
  final listings = await ref.watch(listingsForMatchStreamProvider.future);
  final customerMap = _customerToMapForMatch(customer);
  final listingsMaps = listings.map((e) => e.toMap()).toList();
  final input = <String, dynamic>{'customer': customerMap, 'listings': listingsMaps};
  final raw = await compute(computeTopMatchedListings, input);
  return raw.map((m) => MatchedListingDisplay(
        listingId: m['listingId'] as String? ?? '',
        title: m['title'] as String? ?? 'İlan',
        score: (m['score'] as num?)?.toDouble() ?? 0,
        confidenceScore: (m['confidenceScore'] as num?)?.toDouble() ?? 0,
        aiExplanation: m['aiExplanation'] as String?,
      )).toList();
});

Map<String, dynamic> _customerToMapForMatch(CustomerEntity c) => {
      'id': c.id,
      'budgetMin': c.budgetMin,
      'budgetMax': c.budgetMax,
      'regionPreferences': c.regionPreferences,
      'tags': c.tags,
    };

/// Ekranda gösterim için: eşleşen ilan + başlık + skor.
class MatchedListingDisplay {
  const MatchedListingDisplay({
    required this.listingId,
    required this.title,
    this.score = 0,
    this.confidenceScore = 0,
    this.aiExplanation,
  });
  final String listingId;
  final String title;
  final double score;
  final double confidenceScore;
  final String? aiExplanation;
}
