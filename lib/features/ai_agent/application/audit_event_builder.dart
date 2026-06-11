import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';

/// Denetim olayı üretici — öneri yaşam döngüsünün her adımını kaydeder.
abstract final class AuditEventBuilder {
  static int _counter = 0;

  static AxionAuditEvent build({
    required AxionAuditEventType eventType,
    required String userId,
    required String role,
    required String workspaceId,
    required AxionAgentSourceType sourceType,
    AxionAgentActionType? actionType,
    String targetType = '',
    String targetId = '',
    String? suggestionId,
    AxionAgentApprovalStatus? approvalStatus,
    DateTime? timestamp,
    Map<String, Object?> metadata = const {},
  }) {
    final ts = timestamp ?? DateTime.now();
    _counter = (_counter + 1) % 1000000;
    return AxionAuditEvent(
      id: 'audit-${ts.microsecondsSinceEpoch}-$_counter',
      userId: userId,
      role: role,
      workspaceId: workspaceId,
      eventType: eventType,
      sourceType: sourceType,
      actionType: actionType,
      targetType: targetType,
      targetId: targetId,
      suggestionId: suggestionId,
      approvalStatus: approvalStatus,
      timestamp: ts,
      metadata: metadata,
    );
  }

  static AxionAuditEvent fromSuggestion({
    required AxionAuditEventType eventType,
    required AxionAgentSuggestion suggestion,
    required String userId,
    required String role,
    required String workspaceId,
    DateTime? timestamp,
  }) {
    return build(
      eventType: eventType,
      userId: userId,
      role: role,
      workspaceId: workspaceId,
      sourceType: suggestion.sourceType,
      actionType: suggestion.actionType,
      targetType: suggestion.targetType,
      targetId: suggestion.targetId,
      suggestionId: suggestion.id,
      approvalStatus: suggestion.approvalStatus,
      timestamp: timestamp,
    );
  }
}
