import 'package:equatable/equatable.dart';

import 'deal_health.dart';

/// Pipeline aşaması (hunisi).
enum PipelineStage {
  lead('lead', 'Lead'),
  qualified('qualified', 'Nitelenmiş'),
  proposal('proposal', 'Teklif'),
  negotiation('negotiation', 'Pazarlık'),
  closedWon('closed_won', 'Kazanıldı'),
  closedLost('closed_lost', 'Kaybedildi');

  const PipelineStage(this.id, this.label);
  final String id;
  final String label;

  static PipelineStage fromId(String? id) {
    if (id == null || id.isEmpty) return PipelineStage.lead;
    return PipelineStage.values.firstWhere(
      (e) => e.id == id,
      orElse: () => PipelineStage.lead,
    );
  }
}

/// Pipeline öğesi (satış fırsatı); Deal Health ile ilişkili.
class PipelineItemEntity with EquatableMixin {
  const PipelineItemEntity({
    required this.id,
    required this.customerId,
    this.listingId,
    required this.advisorId,
    this.stage = PipelineStage.lead,
    this.dealHealth,
    this.value,
    this.currency = 'TRY',
    this.lastInteractionAt,
    this.nextActionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String? listingId;
  final String advisorId;
  final PipelineStage stage;
  final DealHealthScore? dealHealth;
  final double? value;
  final String currency;
  final DateTime? lastInteractionAt;
  final DateTime? nextActionAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, stage, updatedAt];
}
