import 'package:flutter/foundation.dart' show immutable, listEquals;

import 'axion_agent_enums.dart';

// ---------------------------------------------------------------------------
// GİRDİ SNAPSHOT DTO'LARI (adapter katmanı)
// Mevcut repository'lere dokunulmaz; çağıran taraf CRM verisini bu saf
// DTO'lara map eder. Motorların hiçbir provider/Firestore bağımlılığı yoktur.
// ---------------------------------------------------------------------------

@immutable
class AxionCustomerSnapshot {
  const AxionCustomerSnapshot({
    required this.id,
    this.name = '',
    this.phone,
    this.region,
    this.budgetMin,
    this.budgetMax,
    this.propertyType,
    this.roomCount,
    this.intent,
    this.temperature = AxionCustomerTemperature.unknown,
    this.lastContactAt,
    this.isActive = true,
    this.preferredDistricts = const [],
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? region;
  final num? budgetMin;
  final num? budgetMax;
  final String? propertyType;
  final int? roomCount;
  final String? intent;
  final AxionCustomerTemperature temperature;
  final DateTime? lastContactAt;
  final bool isActive;
  final List<String> preferredDistricts;
  final DateTime? updatedAt;

  bool get hasBudget => budgetMin != null || budgetMax != null;
  bool get hasRegion => (region ?? '').trim().isNotEmpty;
  bool get hasPropertyType => (propertyType ?? '').trim().isNotEmpty;
  bool get hasIntent => (intent ?? '').trim().isNotEmpty;
  bool get hasPhone => (phone ?? '').trim().isNotEmpty;
}

@immutable
class AxionTaskSnapshot {
  const AxionTaskSnapshot({
    required this.id,
    this.customerId,
    this.title = '',
    this.isCompleted = false,
    this.isFollowUp = false,
    this.dueAt,
    this.updatedAt,
  });

  final String id;
  final String? customerId;
  final String title;
  final bool isCompleted;
  final bool isFollowUp;
  final DateTime? dueAt;
  final DateTime? updatedAt;

  bool isOverdue(DateTime now) =>
      !isCompleted && dueAt != null && dueAt!.isBefore(now);
}

@immutable
class AxionCallSnapshot {
  const AxionCallSnapshot({
    required this.id,
    this.customerId,
    this.phoneNumber,
    this.isMissedOrNoAnswer = false,
    required this.at,
  });

  final String id;
  final String? customerId;
  final String? phoneNumber;
  final bool isMissedOrNoAnswer;
  final DateTime at;
}

@immutable
class AxionListingSnapshot {
  const AxionListingSnapshot({
    required this.id,
    this.title = '',
    this.region,
    this.price,
    this.propertyType,
    this.roomCount,
    this.status,
    this.hasCoverImage = false,
    this.description,
    this.hasOwnerContact = false,
    this.hasLocation = false,
    this.features = const [],
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? region;
  final num? price;
  final String? propertyType;
  final int? roomCount;
  final String? status;
  final bool hasCoverImage;
  final String? description;
  final bool hasOwnerContact;
  final bool hasLocation;
  final List<String> features;
  final DateTime? updatedAt;

  bool get isActive =>
      status == null || status == 'active' || status == 'published';
}

// ---------------------------------------------------------------------------
// BAĞLAM
// ---------------------------------------------------------------------------

@immutable
class AxionAgentContext {
  const AxionAgentContext({
    required this.userId,
    required this.role,
    required this.workspaceId,
    required this.now,
    this.mode = AxionAgentMode.freeRules,
    this.locale = 'tr',
    this.customerSnapshot,
    this.customerSnapshots = const [],
    this.taskSnapshots = const [],
    this.callSnapshots = const [],
    this.listingSnapshots = const [],
    this.portfolioSnapshots = const [],
    this.permissions = const {},
    this.settings = const {},
  });

  final String userId;

  /// 'consultant' | 'manager' | 'broker' | 'admin' ...
  final String role;
  final String workspaceId;
  final DateTime now;
  final AxionAgentMode mode;
  final String locale;

  /// Tek müşteri odaklı işlemler için (müşteri detayı entegrasyonu).
  final AxionCustomerSnapshot? customerSnapshot;
  final List<AxionCustomerSnapshot> customerSnapshots;
  final List<AxionTaskSnapshot> taskSnapshots;
  final List<AxionCallSnapshot> callSnapshots;
  final List<AxionListingSnapshot> listingSnapshots;
  final List<AxionListingSnapshot> portfolioSnapshots;
  final Set<String> permissions;
  final Map<String, Object?> settings;

  bool get isManagerTier =>
      role == 'manager' || role == 'broker' || role == 'admin';
}

// ---------------------------------------------------------------------------
// ÖNERİ + EYLEM
// ---------------------------------------------------------------------------

@immutable
class AxionRecommendedAction {
  const AxionRecommendedAction({
    required this.type,
    required this.title,
    this.description = '',
    this.payload = const {},
    required this.requiresApproval,
    this.blockedReason,
    this.externalChannelWarning,
  });

  final AxionAgentActionType type;
  final String title;
  final String description;
  final Map<String, Object?> payload;
  final bool requiresApproval;
  final String? blockedReason;
  final String? externalChannelWarning;
}

@immutable
class AxionAgentSuggestion {
  const AxionAgentSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.reason,
    required this.sourceType,
    required this.confidence,
    required this.urgency,
    required this.actionType,
    this.recommendedAction,
    this.targetType = '',
    this.targetId = '',
    required this.createdAt,
    this.expiresAt,
    this.honestyNote,
    this.missingData = const [],
    this.evidence = const [],
    this.approvalStatus = AxionAgentApprovalStatus.pending,
  });

  final String id;
  final String title;
  final String description;

  /// "Sebep" — her öneri gerekçesini açıklamak zorundadır.
  final String reason;
  final AxionAgentSourceType sourceType;
  final AxionAgentConfidence confidence;
  final AxionAgentUrgency urgency;
  final AxionAgentActionType actionType;
  final AxionRecommendedAction? recommendedAction;

  /// 'customer' | 'task' | 'call' | 'listing' | 'consultant'
  final String targetType;
  final String targetId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? honestyNote;
  final List<String> missingData;

  /// Gerçek veri kanıtları (ör. "Son temas: 12 gün önce").
  final List<String> evidence;
  final AxionAgentApprovalStatus approvalStatus;

  AxionAgentSuggestion copyWith({AxionAgentApprovalStatus? approvalStatus}) {
    return AxionAgentSuggestion(
      id: id,
      title: title,
      description: description,
      reason: reason,
      sourceType: sourceType,
      confidence: confidence,
      urgency: urgency,
      actionType: actionType,
      recommendedAction: recommendedAction,
      targetType: targetType,
      targetId: targetId,
      createdAt: createdAt,
      expiresAt: expiresAt,
      honestyNote: honestyNote,
      missingData: missingData,
      evidence: evidence,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  /// Tekilleştirme anahtarı: aynı hedef + aynı eylem = tek öneri.
  String get dedupeKey => '$targetType|$targetId|${actionType.name}';
}

// ---------------------------------------------------------------------------
// MESAJ TASLAĞI
// ---------------------------------------------------------------------------

@immutable
class AxionMessageDraft {
  const AxionMessageDraft({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.tone,
    this.targetCustomerId = '',
    this.sourceType = AxionAgentSourceType.template,
    this.requiresReview = true,
    this.honestyNote,
    this.externalChannelWarning,
  });

  final String id;
  final AxionMessageChannel channel;
  final String title;
  final String body;
  final AxionMessageTone tone;
  final String targetCustomerId;
  final AxionAgentSourceType sourceType;

  /// Şablon taslakları HER ZAMAN inceleme gerektirir; otomatik gönderim yok.
  final bool requiresReview;
  final String? honestyNote;
  final String? externalChannelWarning;
}

// ---------------------------------------------------------------------------
// GÜNLÜK PLAN + BROKER ÖZETİ
// ---------------------------------------------------------------------------

@immutable
class AxionDailyPlan {
  const AxionDailyPlan({
    required this.date,
    required this.consultantId,
    this.topPriorities = const [],
    this.overdueTasks = const [],
    this.customersToCall = const [],
    this.messageDrafts = const [],
    this.incompleteRecords = const [],
    this.portfolioMatchReviews = const [],
    this.honestyNote,
    required this.generatedAt,
  });

  final DateTime date;
  final String consultantId;
  final List<AxionAgentSuggestion> topPriorities;
  final List<AxionAgentSuggestion> overdueTasks;
  final List<AxionAgentSuggestion> customersToCall;
  final List<AxionMessageDraft> messageDrafts;
  final List<AxionAgentSuggestion> incompleteRecords;
  final List<AxionAgentSuggestion> portfolioMatchReviews;
  final String? honestyNote;
  final DateTime generatedAt;

  bool get isEmpty =>
      topPriorities.isEmpty &&
      overdueTasks.isEmpty &&
      customersToCall.isEmpty &&
      messageDrafts.isEmpty &&
      incompleteRecords.isEmpty &&
      portfolioMatchReviews.isEmpty;
}

/// Gerçek sayımlar — sahte trend/projeksiyon YOK.
@immutable
class AxionBrokerRealCounts {
  const AxionBrokerRealCounts({
    this.overdueTasks = 0,
    this.missedCallsWithoutCallback = 0,
    this.customersWithoutFollowUp = 0,
    this.incompleteCustomerRecords = 0,
    this.incompleteListings = 0,
    this.hotCustomersWaiting = 0,
    this.tasksDueToday = 0,
  });

  final int overdueTasks;
  final int missedCallsWithoutCallback;
  final int customersWithoutFollowUp;
  final int incompleteCustomerRecords;
  final int incompleteListings;
  final int hotCustomersWaiting;
  final int tasksDueToday;
}

@immutable
class AxionBrokerBrief {
  const AxionBrokerBrief({
    required this.date,
    required this.workspaceId,
    required this.realCounts,
    this.attentionAreas = const [],
    this.teamRisks = const [],
    this.suggestedReviews = const [],
    this.incompleteDataNotes = const [],
    this.honestyNote,
    required this.generatedAt,
  });

  final DateTime date;
  final String workspaceId;
  final AxionBrokerRealCounts realCounts;
  final List<AxionAgentSuggestion> attentionAreas;
  final List<String> teamRisks;
  final List<AxionAgentSuggestion> suggestedReviews;
  final List<String> incompleteDataNotes;
  final String? honestyNote;
  final DateTime generatedAt;
}

// ---------------------------------------------------------------------------
// MÜŞTERİ SİNYALLERİ
// ---------------------------------------------------------------------------

@immutable
class CustomerSignals {
  const CustomerSignals({
    required this.customerId,
    this.isSilent = false,
    this.isHot = false,
    this.hasMissingBudget = false,
    this.hasMissingRegion = false,
    this.hasMissingIntent = false,
    this.hasMissingPhone = false,
    this.hasMissedCall = false,
    this.hasOverdueTask = false,
    this.hasNoActiveFollowUp = false,
    this.hasPortfolioMatchPotential = false,
    this.dataCompletenessPercent = 0,
    this.recommendedNextStep = AxionAgentActionType.noAction,
    this.silentDays,
  });

  final String customerId;
  final bool isSilent;
  final bool isHot;
  final bool hasMissingBudget;
  final bool hasMissingRegion;
  final bool hasMissingIntent;
  final bool hasMissingPhone;
  final bool hasMissedCall;
  final bool hasOverdueTask;
  final bool hasNoActiveFollowUp;
  final bool hasPortfolioMatchPotential;

  /// 0-100 arası; doldurulmuş kritik alan oranı. Sahte skor değildir —
  /// yalnızca alan sayımıdır.
  final int dataCompletenessPercent;
  final AxionAgentActionType recommendedNextStep;
  final int? silentDays;
}

// ---------------------------------------------------------------------------
// PORTFÖY EŞLEŞME
// ---------------------------------------------------------------------------

@immutable
class PortfolioMatchSuggestion {
  const PortfolioMatchSuggestion({
    required this.listingId,
    required this.customerId,
    this.matchReasons = const [],
    this.missingFields = const [],
    required this.confidence,
    this.honestyNote,
  });

  final String listingId;
  final String customerId;
  final List<String> matchReasons;
  final List<String> missingFields;
  final AxionAgentConfidence confidence;
  final String? honestyNote;

  @override
  bool operator ==(Object other) =>
      other is PortfolioMatchSuggestion &&
      other.listingId == listingId &&
      other.customerId == customerId &&
      listEquals(other.matchReasons, matchReasons) &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(listingId, customerId, confidence);
}

// ---------------------------------------------------------------------------
// DENETİM (AUDIT)
// ---------------------------------------------------------------------------

@immutable
class AxionAuditEvent {
  const AxionAuditEvent({
    required this.id,
    required this.userId,
    required this.role,
    required this.workspaceId,
    required this.eventType,
    required this.sourceType,
    this.actionType,
    this.targetType = '',
    this.targetId = '',
    this.suggestionId,
    this.approvalStatus,
    required this.timestamp,
    this.metadata = const {},
  });

  final String id;
  final String userId;
  final String role;
  final String workspaceId;
  final AxionAuditEventType eventType;
  final AxionAgentSourceType sourceType;
  final AxionAgentActionType? actionType;
  final String targetType;
  final String targetId;
  final String? suggestionId;
  final AxionAgentApprovalStatus? approvalStatus;
  final DateTime timestamp;
  final Map<String, Object?> metadata;
}

// ---------------------------------------------------------------------------
// GATE KARARI
// ---------------------------------------------------------------------------

@immutable
class AxionAgentGateDecision {
  const AxionAgentGateDecision({
    required this.allowed,
    required this.sourceType,
    required this.reason,
    this.blockedReason,
    this.useCache = false,
    this.requiresApproval = false,
    this.requiresNetwork = false,
    this.requiresPaidProvider = false,
  });

  final bool allowed;
  final AxionAgentSourceType sourceType;
  final String reason;
  final String? blockedReason;
  final bool useCache;
  final bool requiresApproval;
  final bool requiresNetwork;
  final bool requiresPaidProvider;
}
