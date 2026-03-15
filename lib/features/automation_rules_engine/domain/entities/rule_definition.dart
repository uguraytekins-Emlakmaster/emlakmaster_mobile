import 'package:equatable/equatable.dart';

/// Otomasyon kuralı tetikleyici tipi.
enum RuleTrigger {
  afterCallSummary('after_call_summary'),
  leadTemperatureUrgent('lead_temperature_urgent'),
  noInteractionDays('no_interaction_days'),
  afterVisit('after_visit'),
  afterOffer('after_offer');

  const RuleTrigger(this.id);
  final String id;

  static RuleTrigger fromId(String? id) {
    if (id == null || id.isEmpty) return RuleTrigger.afterCallSummary;
    return RuleTrigger.values.firstWhere(
      (e) => e.id == id,
      orElse: () => RuleTrigger.afterCallSummary,
    );
  }
}

/// Kural tanımı (extendable, safe execution, no duplicate task).
class RuleDefinition with EquatableMixin {
  const RuleDefinition({
    required this.id,
    required this.trigger,
    this.triggerParam,
    this.actionType,
    this.enabled = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final RuleTrigger trigger;
  final String? triggerParam;
  final String? actionType;
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, trigger, enabled];
}
