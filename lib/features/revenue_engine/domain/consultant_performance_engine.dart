import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';

/// Günlük / haftalık özetten tek sayı (liderlik için).
int computeConsultantPerformanceScore(ConsultantActivityRollup r) {
  var s = 0;
  s += r.callsMade * 5;
  s += r.successfulCalls * 10;
  s += r.appointmentsCreated * 20;
  s += r.salesCount * 30;
  s += r.offersRecorded * 8;
  s -= r.missedFollowUps * 10;
  s -= r.inactivityPenaltyDays * 5;
  if (s < 0) return 0;
  if (s > 10000) return 10000;
  return s;
}
