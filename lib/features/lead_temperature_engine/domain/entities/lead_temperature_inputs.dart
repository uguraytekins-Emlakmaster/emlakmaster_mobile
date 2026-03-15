import 'package:equatable/equatable.dart';

/// Lead Temperature Engine girdileri (müşteri + çağrı/ziyaret/teklif sinyalleri).
class LeadTemperatureInputs with EquatableMixin {
  const LeadTemperatureInputs({
    this.lastContactAt,
    this.callCountLast30Days = 0,
    this.lastCallSentimentScore,
    this.budgetClarityScore,
    this.regionClarityScore,
    this.hasOffer = false,
    this.hasVisit = false,
    this.responseSpeedScore,
    this.daysSinceLastContact,
  });

  final DateTime? lastContactAt;
  final int callCountLast30Days;
  final double? lastCallSentimentScore;
  final double? budgetClarityScore;
  final double? regionClarityScore;
  final bool hasOffer;
  final bool hasVisit;
  final double? responseSpeedScore;
  final int? daysSinceLastContact;

  @override
  List<Object?> get props => [
        lastContactAt,
        callCountLast30Days,
        lastCallSentimentScore,
        budgetClarityScore,
        regionClarityScore,
        hasOffer,
        hasVisit,
        responseSpeedScore,
        daysSinceLastContact,
      ];
}
