import 'package:equatable/equatable.dart';

/// İlan likidite / talep skoru (Listing Liquidity Score).
class ListingLiquidityScore with EquatableMixin {
  const ListingLiquidityScore({
    this.liquidityScore = 0.0,
    this.demandScore = 0.0,
    this.pricingTensionIndicator,
    this.lastComputedAt,
  });

  final double liquidityScore;
  final double demandScore;
  /// 'low' | 'medium' | 'high'
  final String? pricingTensionIndicator;
  final DateTime? lastComputedAt;

  @override
  List<Object?> get props => [liquidityScore, demandScore, pricingTensionIndicator];
}
