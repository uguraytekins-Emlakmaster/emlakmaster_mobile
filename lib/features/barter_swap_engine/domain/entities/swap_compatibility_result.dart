import 'package:emlakmaster_mobile/shared/models/strategic_listing_models.dart';
import 'package:equatable/equatable.dart';

/// Takas Zekası çıktısı: skor + karar + güncelleme zamanı (Data Integrity).
class SwapCompatibilityResult with EquatableMixin {
  const SwapCompatibilityResult({
    required this.listingId,
    required this.score,
    required this.verdict,
    required this.lastUpdated,
    this.counterValueEstimate,
    this.explanation,
  });

  final String listingId;
  final double score;
  final SwapCompatibilityVerdict verdict;
  final DateTime lastUpdated;
  final double? counterValueEstimate;
  final String? explanation;

  @override
  List<Object?> get props => [listingId, score, verdict, lastUpdated];
}
