import 'package:equatable/equatable.dart';

/// Listing momentum sinyali (Listing Momentum Engine).
enum MomentumSignal {
  heatingUp('heating_up', 'Isınıyor'),
  stable('stable', 'Stabil'),
  cooling('cooling', 'Soğuyor'),
  overpricedRisk('overpriced_risk', 'Pahalı risk');

  const MomentumSignal(this.id, this.label);
  final String id;
  final String label;
}

/// Fiyat konumu (Price Intelligence).
enum PricingPosition {
  cheap('cheap', 'Ucuz'),
  normal('normal', 'Normal'),
  expensive('expensive', 'Pahalı');

  const PricingPosition(this.id, this.label);
  final String id;
  final String label;
}

/// Kapanma tahmini (Deal Timeline Prediction).
enum DealTimelinePrediction {
  days3('3_days', '3 gün'),
  week1('1_week', '1 hafta'),
  week2('2_weeks', '2 hafta'),
  uncertain('uncertain', 'Belirsiz');

  const DealTimelinePrediction(this.id, this.label);
  final String id;
  final String label;
}

/// Tüm skorlar tek yapıda (Firestore metadata/analytics'e yazılır; UI sadece okur).
class ListingIntelligenceScores with EquatableMixin {
  const ListingIntelligenceScores({
    required this.listingId,
    this.momentumScore = 0.0,
    this.momentumSignal = MomentumSignal.stable,
    this.pricingPositionScore = 0.0,
    this.pricingPosition = PricingPosition.normal,
    this.velocityScore = 0.0,
    this.regionDemandScore = 0.0,
    this.computedAt,
  });

  final String listingId;
  final double momentumScore;
  final MomentumSignal momentumSignal;
  final double pricingPositionScore;
  final PricingPosition pricingPosition;
  final double velocityScore;
  final double regionDemandScore;
  final DateTime? computedAt;

  @override
  List<Object?> get props => [listingId, computedAt];
}

class CustomerIntelligenceScores with EquatableMixin {
  const CustomerIntelligenceScores({
    required this.customerId,
    this.fitScoreForListing = 0.0,
    this.psychologySignals = const [],
    this.dealRiskScore = 0.0,
    this.clvEstimate,
    this.reactivationSuggestion,
    this.computedAt,
  });

  final String customerId;
  final double fitScoreForListing;
  final List<String> psychologySignals;
  final double dealRiskScore;
  final double? clvEstimate;
  final String? reactivationSuggestion;
  final DateTime? computedAt;

  @override
  List<Object?> get props => [customerId, computedAt];
}

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

class BuyerCluster with EquatableMixin {
  const BuyerCluster({
    required this.id,
    this.label,
    this.regionId,
    this.budgetMin,
    this.budgetMax,
    this.customerType,
    this.customerIds = const [],
    this.computedAt,
  });

  final String id;
  final String? label;
  final String? regionId;
  final double? budgetMin;
  final double? budgetMax;
  final String? customerType;
  final List<String> customerIds;
  final DateTime? computedAt;

  @override
  List<Object?> get props => [id, label];
}

class DailyBriefItem with EquatableMixin {
  const DailyBriefItem({
    required this.id,
    this.category,
    this.title,
    this.subtitle,
    this.priority = 0,
    this.computedAt,
  });

  final String id;
  final String? category;
  final String? title;
  final String? subtitle;
  final int priority;
  final DateTime? computedAt;

  @override
  List<Object?> get props => [id, category];
}

class MissedOpportunityItem with EquatableMixin {
  const MissedOpportunityItem({
    required this.id,
    this.customerId,
    this.reason,
    this.score = 0.0,
    this.computedAt,
  });

  final String id;
  final String? customerId;
  final String? reason;
  final double score;
  final DateTime? computedAt;

  @override
  List<Object?> get props => [id, reason];
}
