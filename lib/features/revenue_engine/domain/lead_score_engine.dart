import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/customer_signal_inputs.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';

/// Kural tabanlı lead skoru (0–100). Ağır sorgu yok; girdi özetine göre hesaplanır.
int computeLeadScore(CustomerSignalInputs in_, DateTime now) {
  var s = 0;

  final last = in_.lastContactAt;
  if (last != null) {
    final hours = now.difference(last).inHours;
    if (hours <= 24) s += 15;
    if (now.difference(last).inDays >= 3) s -= 15;
  } else {
    s -= 15;
  }

  final code = in_.lastCallOutcomeCode;
  if (isSuccessfulReach(code)) s += 20;
  if (isNoAnswer(code)) s -= 20;
  if (code == QuickCallOutcome.callbackScheduled) s += 10;
  if (isOffer(code) || in_.hasOfferFromCrm) s += 10;
  if (isAppointment(code) || in_.hasAppointmentFromCalls) s += 15;

  if (in_.firestoreCallCount >= 2) s += 10;
  if (in_.noAnswerCountRecent >= 2) s -= 10;

  if (in_.localUnsyncedWithCustomer) {
    s -= 5;
  }

  if (s < 0) return 0;
  if (s > 100) return 100;
  return s;
}
