import 'package:emlakmaster_mobile/features/smart_matching_engine/domain/entities/match_result.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Bütçe, bölge, mülk tipi ve objection (örn. havuz_istemiyor) ile skorlama.
class ScoreListingMatch {
  /// objectionFlags'ta 'havuz_istemiyor' varsa ve listing havuzluysa skor düşer.
  MatchResult call({
    required CustomerEntity customer,
    required String listingId,
    required double? listingPrice,
    required List<String> listingRegions,
    required String? listingPropertyType,
    required bool listingHasPool,
    required List<String> objectionFlags,
  }) {
    var score = 0.0;
    var objectionPenalty = 0.0;

    if (listingPrice != null) {
      final min = customer.budgetMin ?? 0.0;
      final max = customer.budgetMax ?? double.infinity;
      if (listingPrice >= min && listingPrice <= max) {
        score += 35;
      } else if (listingPrice <= max * 1.2) {
        score += 15;
      }
    }

    if (listingRegions.isNotEmpty && customer.regionPreferences.isNotEmpty) {
      final match = listingRegions.any((r) =>
          customer.regionPreferences.any((p) => p.toLowerCase().contains(r.toLowerCase()) || r.toLowerCase().contains(p.toLowerCase())));
      if (match) score += 30;
    }

    if (listingHasPool && objectionFlags.any((o) => o.toLowerCase().contains('havuz') || o == 'havuz_istemiyor')) {
      objectionPenalty = 40.0;
    }

    score = (score - objectionPenalty).clamp(0.0, 100.0);
    final confidence = (score / 100).clamp(0.0, 1.0);
    String? explanation;
    if (objectionPenalty > 0) {
      explanation = 'Müşteri havuz istemediği için bu ilanın eşleşme skoru düşürüldü.';
    } else if (score > 50) {
      explanation = 'Bütçe ve bölge tercihlerine uygun.';
    }

    return MatchResult(
      listingId: listingId,
      customerId: customer.id,
      score: score,
      confidenceScore: confidence,
      aiExplanation: explanation,
      objectionPenalty: objectionPenalty > 0 ? objectionPenalty : null,
    );
  }
}
