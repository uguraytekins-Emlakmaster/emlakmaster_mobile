import 'package:equatable/equatable.dart';

class RegionHeatmapScore with EquatableMixin {
  const RegionHeatmapScore({
    required this.regionId,
    required this.regionName,
    this.demandScore = 0.0,
    this.budgetSegment,
    this.propertyTypeHint,
    this.computedAt,
  });

  final String regionId;
  final String regionName;
  final double demandScore;
  final String? budgetSegment;
  final String? propertyTypeHint;
  final DateTime? computedAt;

  @override
  List<Object?> get props => [regionId, computedAt];
}

class DealDiscoveryItem with EquatableMixin {
  const DealDiscoveryItem({
    required this.id,
    this.type = 'hidden_opportunity',
    this.listingId,
    this.customerId,
    this.title,
    this.subtitle,
    this.score = 0.0,
    this.computedAt,
    this.highlights = const [],
  });

  final String id;
  final String type;
  final String? listingId;
  final String? customerId;
  final String? title;
  final String? subtitle;
  final double score;
  final DateTime? computedAt;
  /// Kısa fırsat maddeleri (Firestore: `highlights` — örn. "Son 7 günün en düşük fiyatlısı").
  final List<String> highlights;

  @override
  List<Object?> get props => [id, type, score, highlights];
}
