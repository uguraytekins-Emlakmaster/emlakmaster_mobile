import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/shared/models/call_summary_models.dart';

/// Call summary kaydı: humanEdited/humanApproved korunur, fail durumunda retry.
/// [assignedAgentId] Firestore kuralları (agentId / assignedAgentId) için zorunlu.
class SaveCallSummaryWithRetry {
  Future<void> call(
    CallSummaryEntity summary, {
    required String assignedAgentId,
  }) async {
    final data = <String, dynamic>{
      'id': summary.id,
      'callId': summary.callId,
      'customerId': summary.customerId,
      'agentId': assignedAgentId,
      'assignedAgentId': assignedAgentId,
      'shortSummary': summary.shortSummary,
      'longSummary': summary.longSummary,
      'intent': summary.intent,
      'budgetEstimateMin': summary.budgetEstimateMin,
      'budgetEstimateMax': summary.budgetEstimateMax,
      'locationPreferences': summary.locationPreferences,
      'urgencyLevel': summary.urgencyLevel,
      'sentiment': summary.sentiment,
      'leadTemperature': summary.leadTemperature,
      'objectionFlags': summary.objectionFlags,
      'confidenceScore': summary.confidenceScore,
      'recommendedNextAction': summary.recommendedNextAction,
      'suggestedTaskTitle': summary.suggestedTaskTitle,
      'suggestedPipelineStage': summary.suggestedPipelineStage,
      'managerAttentionFlag': summary.managerAttentionFlag,
      'humanEdited': summary.humanEdited,
      'humanApproved': summary.humanApproved,
      'createdAt': summary.createdAt,
    };
    await FirestoreService.saveCallSummaryDoc(data);
  }
}
