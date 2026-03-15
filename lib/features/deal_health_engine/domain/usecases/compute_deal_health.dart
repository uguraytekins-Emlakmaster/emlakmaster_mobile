import 'package:emlakmaster_mobile/shared/models/deal_health.dart';
import 'package:emlakmaster_mobile/shared/models/pipeline_models.dart';

/// Pipeline öğesi için sağlık ve kapanma ihtimali (Rainbow Predict placeholder).
class ComputeDealHealth {
  DealHealthScore call(PipelineItemEntity item) {
    final factors = <String, double>{};
    var risk = 0.0;

    final last = item.lastInteractionAt;
    if (last != null) {
      final days = DateTime.now().difference(last).inDays;
      if (days > 14) {
        factors['inactivity'] = 1.0;
        risk += 35;
      } else if (days > 7) {
        factors['inactivity'] = 0.6;
        risk += 20;
      }
    } else {
      factors['inactivity'] = 1.0;
      risk += 25;
    }

    if (item.stage == PipelineStage.closedWon || item.stage == PipelineStage.closedLost) {
      risk = 0;
      factors['stage'] = 0.0;
    } else if (item.stage == PipelineStage.negotiation) {
      factors['stage'] = 0.2;
      risk += 5;
    } else if (item.stage == PipelineStage.lead) {
      factors['stage'] = 0.8;
      risk += 15;
    }

    if (item.dealHealth != null && item.dealHealth!.level == DealHealthLevel.critical) {
      risk += 20;
    }

    risk = risk.clamp(0.0, 100.0);
    DealHealthLevel level;
    double? closeProbability;
    if (risk >= 60) {
      level = DealHealthLevel.critical;
      closeProbability = 0.1;
    } else if (risk >= 40) {
      level = DealHealthLevel.risk;
      closeProbability = 0.25;
    } else if (risk >= 20) {
      level = DealHealthLevel.watch;
      closeProbability = 0.5;
    } else {
      level = DealHealthLevel.healthy;
      closeProbability = 0.75;
    }

    return DealHealthScore(
      level: level,
      closeProbabilityPercent: closeProbability * 100,
      lastComputedAt: DateTime.now(),
      factors: factors,
    );
  }
}
