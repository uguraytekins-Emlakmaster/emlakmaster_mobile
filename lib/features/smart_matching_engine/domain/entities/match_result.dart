import 'package:equatable/equatable.dart';

/// Müşteri-ilan eşleşme sonucu (objections dahil: havuz_istemiyor vb. skordan düşürülür).
class MatchResult with EquatableMixin {
  const MatchResult({
    required this.listingId,
    required this.customerId,
    this.score = 0.0,
    this.confidenceScore = 0.0,
    this.aiExplanation,
    this.objectionPenalty,
  });

  final String listingId;
  final String customerId;
  final double score;
  final double confidenceScore;
  final String? aiExplanation;
  /// Örn: havuz_istemiyor → ilan havuzluysa ceza uygulanır.
  final double? objectionPenalty;

  @override
  List<Object?> get props => [listingId, customerId, score, confidenceScore];
}
