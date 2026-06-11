import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';

/// Eylem onay politikası — hiçbir değiştirici eylem onaysız uygulanmaz.
abstract final class ActionApprovalPolicy {
  /// Eylem onay gerektirir mi?
  static bool requiresApproval(AxionAgentActionType type) =>
      AxionAgentPolicy.requiresApproval(type);

  /// Onay durumu geçişi geçerli mi? (yaşam döngüsü koruması)
  static bool canTransition(
    AxionAgentApprovalStatus from,
    AxionAgentApprovalStatus to,
  ) {
    return switch (from) {
      AxionAgentApprovalStatus.pending => to ==
              AxionAgentApprovalStatus.approved ||
          to == AxionAgentApprovalStatus.rejected ||
          to == AxionAgentApprovalStatus.expired,
      AxionAgentApprovalStatus.approved =>
        to == AxionAgentApprovalStatus.applied ||
            to == AxionAgentApprovalStatus.expired,
      // Uygulanan/reddedilen/süresi dolan öneriler değiştirilemez.
      AxionAgentApprovalStatus.rejected ||
      AxionAgentApprovalStatus.applied ||
      AxionAgentApprovalStatus.expired =>
        false,
    };
  }

  /// Öneri uygulanabilir mi? Yalnızca onaylanmış ve süresi geçmemiş öneriler.
  static bool canApply(AxionAgentSuggestion s, DateTime now) {
    if (s.approvalStatus != AxionAgentApprovalStatus.approved) return false;
    if (s.expiresAt != null && s.expiresAt!.isBefore(now)) return false;
    final action = s.recommendedAction;
    if (action == null) return false;
    if (action.blockedReason != null) return false;
    return true;
  }
}
