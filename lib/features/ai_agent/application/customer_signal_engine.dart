import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';

/// Saf, hızlı müşteri sinyal motoru.
///
/// Ağ yok, provider yok, UI yok — yalnızca gerçek snapshot verisinden
/// deterministik sinyaller üretir.
abstract final class CustomerSignalEngine {
  static CustomerSignals compute({
    required AxionCustomerSnapshot customer,
    required List<AxionTaskSnapshot> tasks,
    required List<AxionCallSnapshot> calls,
    required DateTime now,
    bool hasPortfolioCandidates = false,
  }) {
    final silentDays = customer.lastContactAt == null
        ? null
        : now.difference(customer.lastContactAt!).inDays;

    final isHot = customer.temperature == AxionCustomerTemperature.hot;

    final silentThreshold = switch (customer.temperature) {
      AxionCustomerTemperature.hot => AxionAgentPolicy.hotSilentDays,
      AxionCustomerTemperature.warm => AxionAgentPolicy.warmSilentDays,
      _ => AxionAgentPolicy.coldSilentDays,
    };
    final isSilent = silentDays != null && silentDays > silentThreshold;

    var hasMissedCall = false;
    for (final c in calls) {
      if (c.customerId == customer.id && c.isMissedOrNoAnswer) {
        hasMissedCall = true;
        break;
      }
    }

    var hasOverdueTask = false;
    var hasActiveFollowUp = false;
    for (final t in tasks) {
      if (t.customerId != customer.id) continue;
      if (t.isOverdue(now)) hasOverdueTask = true;
      if (!t.isCompleted && (t.isFollowUp || t.dueAt != null)) {
        hasActiveFollowUp = true;
      }
    }

    // Veri tamlığı: 5 kritik alanın doluluk oranı (sahte skor değil, sayım).
    var filled = 0;
    if (customer.hasBudget) filled++;
    if (customer.hasRegion) filled++;
    if (customer.hasPropertyType) filled++;
    if (customer.hasIntent) filled++;
    if (customer.hasPhone) filled++;
    final completeness = (filled * 100) ~/ 5;

    final matchPotential = hasPortfolioCandidates &&
        customer.hasRegion &&
        customer.hasBudget &&
        customer.hasPropertyType;

    return CustomerSignals(
      customerId: customer.id,
      isSilent: isSilent,
      isHot: isHot,
      hasMissingBudget: !customer.hasBudget,
      hasMissingRegion: !customer.hasRegion,
      hasMissingIntent: !customer.hasIntent,
      hasMissingPhone: !customer.hasPhone,
      hasMissedCall: hasMissedCall,
      hasOverdueTask: hasOverdueTask,
      hasNoActiveFollowUp: !hasActiveFollowUp,
      hasPortfolioMatchPotential: matchPotential,
      dataCompletenessPercent: completeness,
      recommendedNextStep: _nextStep(
        isHot: isHot,
        isSilent: isSilent,
        hasMissedCall: hasMissedCall,
        hasOverdueTask: hasOverdueTask,
        hasActiveFollowUp: hasActiveFollowUp,
        completeness: completeness,
        matchPotential: matchPotential,
      ),
      silentDays: silentDays,
    );
  }

  static AxionAgentActionType _nextStep({
    required bool isHot,
    required bool isSilent,
    required bool hasMissedCall,
    required bool hasOverdueTask,
    required bool hasActiveFollowUp,
    required int completeness,
    required bool matchPotential,
  }) {
    if (hasMissedCall) return AxionAgentActionType.callCustomer;
    if (hasOverdueTask) return AxionAgentActionType.createTask;
    if (isHot && !hasActiveFollowUp) return AxionAgentActionType.createTask;
    if (isSilent) return AxionAgentActionType.scheduleFollowUp;
    if (matchPotential) return AxionAgentActionType.reviewPortfolioMatch;
    if (completeness < 60) return AxionAgentActionType.updateCustomerInfo;
    return AxionAgentActionType.noAction;
  }
}
