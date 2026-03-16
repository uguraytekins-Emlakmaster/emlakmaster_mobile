import 'package:equatable/equatable.dart';

/// Tüm AI/stratejik skorlar için: değer + son güncelleme (Data Integrity).
class ScoredAt<T> with EquatableMixin {
  const ScoredAt({required this.value, this.lastUpdated});
  final T value;
  final DateTime? lastUpdated;
  @override
  List<Object?> get props => [value, lastUpdated];
}

/// Takas uyumluluk sonucu (Barter & Swap Engine).
enum SwapCompatibilityVerdict {
  profitable('profitable', 'Karlı'),
  fair('fair', 'Adil'),
  risky('risky', 'Riskli');

  const SwapCompatibilityVerdict(this.id, this.label);
  final String id;
  final String label;
}

/// İlan için stratejik alanlar (Firestore listings dokümanına eklenecek).
/// swap_compatible, investment_score, voice_note_summary, AR/VR meta.
class ListingStrategicFields with EquatableMixin {
  const ListingStrategicFields({
    this.swapCompatible = false,
    this.swapCompatibilityScore,
    this.swapCompatibilityVerdict,
    this.swapCompatibilityUpdatedAt,
    this.investmentScore,
    this.investmentScoreUpdatedAt,
    this.hotspotTags = const [],
    this.voiceNoteSummary,
    this.media360Urls = const [],
    this.lidarScanId,
    this.propertyVaultDocId,
  });

  final bool swapCompatible;
  final double? swapCompatibilityScore;
  final SwapCompatibilityVerdict? swapCompatibilityVerdict;
  final DateTime? swapCompatibilityUpdatedAt;
  final double? investmentScore;
  final DateTime? investmentScoreUpdatedAt;
  final List<String> hotspotTags;
  final String? voiceNoteSummary;
  final List<String> media360Urls;
  final String? lidarScanId;
  final String? propertyVaultDocId;

  @override
  List<Object?> get props => [
        swapCompatible,
        swapCompatibilityScore,
        swapCompatibilityUpdatedAt,
        investmentScore,
        investmentScoreUpdatedAt,
        hotspotTags,
        voiceNoteSummary,
        lidarScanId,
      ];
}
