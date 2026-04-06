import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:equatable/equatable.dart';

/// Lead skoru bandı (gelir motoru — 0–100 skoruna göre).
enum RevenueLeadBand {
  hot,
  warm,
  cold,
}

/// Önerilen sonraki kanal (görev oluşturmaz; yalnızca öneri).
enum RevenueNextActionKind {
  call,
  message,
  wait,
}

/// Tek müşteri için gelir motoru çıktısı (önbellek / UI).
class CustomerRevenueSignals extends Equatable {
  const CustomerRevenueSignals({
    required this.customerId,
    required this.leadScore,
    required this.band,
    required this.valueScore,
    required this.nextAction,
    required this.nextActionTime,
    required this.recommendationSuppressed,
    required this.syncDelayedRisk,
    this.suppressionReason,
  });

  final String customerId;
  final int leadScore;
  final RevenueLeadBand band;
  final int valueScore;
  final RevenueNextActionKind nextAction;
  final DateTime nextActionTime;
  final bool recommendationSuppressed;
  /// [sync_delayed_risk] — dashboard satırı ayrı `Set` izlemesine ihtiyaç duymaz.
  final bool syncDelayedRisk;
  final String? suppressionReason;

  @override
  List<Object?> get props => [
        customerId,
        leadScore,
        band,
        valueScore,
        nextAction,
        nextActionTime,
        recommendationSuppressed,
        syncDelayedRisk,
        suppressionReason,
      ];
}

/// Danışman performans özeti (günlük / haftalık agregasyon girişi).
class ConsultantActivityRollup extends Equatable {
  const ConsultantActivityRollup({
    required this.advisorId,
    required this.callsMade,
    required this.successfulCalls,
    required this.appointmentsCreated,
    required this.offersRecorded,
    required this.missedFollowUps,
    required this.inactivityPenaltyDays,
    this.salesCount = 0,
  });

  final String advisorId;
  final int callsMade;
  final int successfulCalls;
  final int appointmentsCreated;
  final int offersRecorded;
  final int missedFollowUps;
  final int inactivityPenaltyDays;
  final int salesCount;

  @override
  List<Object?> get props => [advisorId, callsMade, successfulCalls, appointmentsCreated];
}

/// Sıralama satırı (ofis lider tablosu için hazır).
class ConsultantLeaderboardEntry extends Equatable {
  const ConsultantLeaderboardEntry({
    required this.advisorId,
    required this.displayLabel,
    required this.performanceScore,
    this.rank,
  });

  final String advisorId;
  final String displayLabel;
  final int performanceScore;
  final int? rank;

  @override
  List<Object?> get props => [advisorId, performanceScore, rank];
}

/// Dashboard tek karelik özet (hafif widget’lar için).
class RevenueDashboardSnapshot extends Equatable {
  const RevenueDashboardSnapshot({
    required this.hotCustomers,
    required this.actionToday,
    required this.atRiskSync,
    required this.selfPerformanceScore,
    required this.leaderboard,
  });

  final List<CustomerRevenueRow> hotCustomers;
  final List<CustomerRevenueRow> actionToday;
  final List<CustomerRevenueRow> atRiskSync;
  final int selfPerformanceScore;
  final List<ConsultantLeaderboardEntry> leaderboard;

  @override
  List<Object?> get props => [hotCustomers.length, actionToday.length, atRiskSync.length, selfPerformanceScore];
}

/// Özet satır (isim + skor + aksiyon).
class CustomerRevenueRow extends Equatable {
  const CustomerRevenueRow({
    required this.customerId,
    required this.displayName,
    required this.leadScore,
    required this.valueScore,
    required this.band,
    required this.nextAction,
    required this.nextActionTime,
    this.syncDelayedRisk = false,
  });

  final String customerId;
  final String displayName;
  final int leadScore;
  final int valueScore;
  final RevenueLeadBand band;
  final RevenueNextActionKind nextAction;
  final DateTime nextActionTime;
  final bool syncDelayedRisk;

  @override
  List<Object?> get props => [customerId, leadScore, valueScore, nextActionTime, syncDelayedRisk];
}

/// Son çağrı sonucu kodu (Firestore / hızlı yakalama ile uyumlu).
String? normalizeCallOutcomeCode(Map<String, dynamic> data) {
  final q = data['quickOutcomeCode'] as String? ?? data['quickOutcome'] as String?;
  if (q != null && q.trim().isNotEmpty) return q.trim();
  final o = data['outcome'] as String? ?? data['callOutcome'] as String?;
  if (o != null && o.trim().isNotEmpty) return o.trim();
  return null;
}

bool isSuccessfulReach(String? code) => code == QuickCallOutcome.reached;

bool isNoAnswer(String? code) => code == QuickCallOutcome.noAnswer;

bool isBusy(String? code) => code == QuickCallOutcome.busy;

bool isOffer(String? code) => code == QuickCallOutcome.offerSent;

bool isAppointment(String? code) => code == QuickCallOutcome.appointmentSet;

bool isPositiveInterest(String? code) {
  if (code == null) return false;
  return code == QuickCallOutcome.reached ||
      code == QuickCallOutcome.callbackScheduled ||
      code == QuickCallOutcome.appointmentSet ||
      code == QuickCallOutcome.offerSent;
}
