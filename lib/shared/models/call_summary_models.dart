import 'package:equatable/equatable.dart';

/// AI çağrı özeti entity (AI Call Brain genişletmesi).
class CallSummaryEntity with EquatableMixin {
  const CallSummaryEntity({
    required this.id,
    required this.callId,
    this.customerId,
    this.shortSummary,
    this.longSummary,
    this.intent,
    this.budgetEstimateMin,
    this.budgetEstimateMax,
    this.locationPreferences = const [],
    this.urgencyLevel,
    this.sentiment,
    this.leadTemperature,
    this.objectionFlags = const [],
    this.confidenceScore,
    this.recommendedNextAction,
    this.suggestedTaskTitle,
    this.suggestedPipelineStage,
    this.managerAttentionFlag = false,
    this.humanEdited = false,
    this.humanApproved = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String callId;
  final String? customerId;
  final String? shortSummary;
  final String? longSummary;
  final String? intent;
  final double? budgetEstimateMin;
  final double? budgetEstimateMax;
  final List<String> locationPreferences;
  final String? urgencyLevel;
  final String? sentiment;
  final double? leadTemperature;
  /// Örn: ['havuz_istemiyor', 'acil_taşınma']
  final List<String> objectionFlags;
  final double? confidenceScore;
  final String? recommendedNextAction;
  final String? suggestedTaskTitle;
  final String? suggestedPipelineStage;
  final bool managerAttentionFlag;
  final bool humanEdited;
  final bool humanApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, callId, createdAt];
}
