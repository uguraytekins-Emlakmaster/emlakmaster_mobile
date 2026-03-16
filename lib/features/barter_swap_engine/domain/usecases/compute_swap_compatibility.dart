import 'package:emlakmaster_mobile/features/barter_swap_engine/domain/entities/swap_compatibility_result.dart';
import 'package:emlakmaster_mobile/shared/models/strategic_listing_models.dart';

/// Takas Zekası: İlan değeri vs karşı taraf (araç/arsa) tahmini değer.
/// Profitable / Fair / Risky.
class ComputeSwapCompatibility {
  SwapCompatibilityResult call({
    required String listingId,
    required double listingPriceEstimate,
    required double counterPartyValueEstimate,
    String? explanation,
  }) {
    if (counterPartyValueEstimate <= 0) {
      return SwapCompatibilityResult(
        listingId: listingId,
        score: 0,
        verdict: SwapCompatibilityVerdict.risky,
        lastUpdated: DateTime.now(),
        counterValueEstimate: counterPartyValueEstimate,
        explanation: explanation ?? 'Karşı taraf değeri hesaplanamadı.',
      );
    }
    final ratio = listingPriceEstimate / counterPartyValueEstimate;
    double score;
    SwapCompatibilityVerdict verdict;
    if (ratio <= 0.85) {
      score = 85 + (1 - ratio) * 15;
      verdict = SwapCompatibilityVerdict.profitable;
    } else if (ratio <= 1.15) {
      score = 50 + (1.15 - ratio) * 50;
      verdict = SwapCompatibilityVerdict.fair;
    } else {
      score = (1.5 - ratio).clamp(0.0, 1.0) * 50;
      verdict = SwapCompatibilityVerdict.risky;
    }
    score = score.clamp(0.0, 100.0);
    return SwapCompatibilityResult(
      listingId: listingId,
      score: score,
      verdict: verdict,
      lastUpdated: DateTime.now(),
      counterValueEstimate: counterPartyValueEstimate,
      explanation: explanation ?? (verdict == SwapCompatibilityVerdict.profitable
          ? 'Takas satıcı lehine.'
          : verdict == SwapCompatibilityVerdict.fair
              ? 'Takas dengeli.'
              : 'Takas riskli; karşı taraf değeri düşük.'),
    );
  }
}
