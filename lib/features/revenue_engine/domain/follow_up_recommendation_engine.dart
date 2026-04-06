import 'package:emlakmaster_mobile/features/revenue_engine/domain/customer_signal_inputs.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';

/// Manuel görev varken öneri bastırılır (üzerine yazılmaz).
({RevenueNextActionKind action, DateTime at, bool suppressed, String? reason})
    computeFollowUpRecommendation({
  required CustomerSignalInputs in_,
  required int leadScore,
  required RevenueLeadBand band,
  required DateTime now,
}) {
  if (in_.openManualTask) {
    return (
      action: RevenueNextActionKind.wait,
      at: now,
      suppressed: true,
      reason: 'Açık görev var; öneri yalnızca bilgi amaçlı gizlendi.',
    );
  }

  final code = in_.lastCallOutcomeCode;

  if (isNoAnswer(code)) {
    return (
      action: RevenueNextActionKind.call,
      at: now.add(const Duration(hours: 24)),
      suppressed: false,
      reason: null,
    );
  }
  if (isBusy(code)) {
    return (
      action: RevenueNextActionKind.call,
      at: now.add(const Duration(hours: 3)),
      suppressed: false,
      reason: null,
    );
  }
  if (isOffer(code) || in_.hasOfferFromCrm) {
    return (
      action: RevenueNextActionKind.message,
      at: now.add(const Duration(hours: 48)),
      suppressed: false,
      reason: null,
    );
  }
  if (band == RevenueLeadBand.hot || leadScore >= 70) {
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    final target = endOfDay.isBefore(now) ? now.add(const Duration(hours: 4)) : endOfDay;
    return (
      action: RevenueNextActionKind.call,
      at: target,
      suppressed: false,
      reason: null,
    );
  }
  if (band == RevenueLeadBand.cold) {
    return (
      action: RevenueNextActionKind.wait,
      at: now.add(const Duration(days: 5)),
      suppressed: false,
      reason: null,
    );
  }

  return (
    action: RevenueNextActionKind.call,
    at: now.add(const Duration(days: 1)),
    suppressed: false,
    reason: null,
  );
}
