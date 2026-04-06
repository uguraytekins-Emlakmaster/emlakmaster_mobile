import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:equatable/equatable.dart';

/// Saf skor fonksiyonlarına giren özet (Firestore + yerel özet).
class CustomerSignalInputs extends Equatable {
  const CustomerSignalInputs({
    required this.customerId,
    this.lastContactAt,
    this.lastCallOutcomeCode,
    required this.firestoreCallCount,
    required this.noAnswerCountRecent,
    required this.hasOfferFromCrm,
    required this.hasAppointmentFromCalls,
    required this.localUnsyncedWithCustomer,
    this.openManualTask = false,
  });

  final String customerId;
  final DateTime? lastContactAt;
  final String? lastCallOutcomeCode;
  final int firestoreCallCount;
  /// Son 14 gündeki cevapsız sayısı (tekrarlı başarısız cezası için).
  final int noAnswerCountRecent;
  final bool hasOfferFromCrm;
  final bool hasAppointmentFromCalls;
  /// Bu müşteri için Hive’da senkron bekleyen yerel çağrı var mı?
  final bool localUnsyncedWithCustomer;
  final bool openManualTask;

  @override
  List<Object?> get props => [
        customerId,
        lastContactAt,
        lastCallOutcomeCode,
        firestoreCallCount,
        noAnswerCountRecent,
        hasOfferFromCrm,
        hasAppointmentFromCalls,
        localUnsyncedWithCustomer,
        openManualTask,
      ];
}

RevenueLeadBand bandFromScore(int score) {
  if (score >= 70) return RevenueLeadBand.hot;
  if (score >= 40) return RevenueLeadBand.warm;
  return RevenueLeadBand.cold;
}
