import 'package:emlakmaster_mobile/features/lead_temperature_engine/domain/entities/lead_temperature_inputs.dart';
import 'package:emlakmaster_mobile/shared/models/lead_temperature.dart';

/// Lead Temperature Engine: girdilere göre sıcaklık seviyesi ve skor üretir.
class ComputeLeadTemperature {
  LeadTemperatureScore call(LeadTemperatureInputs inputs) {
    final factors = <String, double>{};
    var score = 0.0;

    final days = inputs.daysSinceLastContact ?? 999;
    if (days <= 1) {
      factors['recency'] = 1.0;
      score += 25;
    } else if (days <= 7) {
      factors['recency'] = 0.7;
      score += 15;
    } else if (days <= 14) {
      factors['recency'] = 0.4;
      score += 5;
    } else if (days >= 30) {
      factors['recency'] = 0.0;
      if (inputs.callCountLast30Days > 0) {
        factors['reactivation'] = 0.5;
        score += 10;
      }
    }

    if (inputs.callCountLast30Days >= 3) {
      factors['call_frequency'] = 1.0;
      score += 15;
    } else if (inputs.callCountLast30Days >= 1) {
      factors['call_frequency'] = 0.5;
      score += 8;
    }

    final sentiment = inputs.lastCallSentimentScore ?? 0.0;
    if (sentiment > 0.6) {
      factors['sentiment'] = sentiment;
      score += sentiment * 15;
    }

    if (inputs.budgetClarityScore != null && inputs.budgetClarityScore! > 0.5) {
      factors['budget_clarity'] = inputs.budgetClarityScore!;
      score += 10;
    }
    if (inputs.regionClarityScore != null && inputs.regionClarityScore! > 0.5) {
      factors['region_clarity'] = inputs.regionClarityScore!;
      score += 10;
    }
    if (inputs.hasOffer) {
      factors['offer'] = 1.0;
      score += 15;
    }
    if (inputs.hasVisit) {
      factors['visit'] = 1.0;
      score += 12;
    }

    score = score.clamp(0.0, 100.0);
    LeadTemperatureLevel level;
    if (score >= 75) {
      level = LeadTemperatureLevel.urgent;
    } else if (score >= 55) {
      level = LeadTemperatureLevel.hot;
    } else if (score >= 35) {
      level = LeadTemperatureLevel.warm;
    } else if (days >= 14 && inputs.callCountLast30Days == 0) {
      level = LeadTemperatureLevel.reactivationCandidate;
    } else {
      level = LeadTemperatureLevel.cold;
    }

    return LeadTemperatureScore(
      level: level,
      score: score,
      lastComputedAt: DateTime.now(),
      factors: factors,
    );
  }
}
