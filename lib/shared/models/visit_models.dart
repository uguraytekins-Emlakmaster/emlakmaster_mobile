import 'package:equatable/equatable.dart';

/// Ziyaret sonucu.
enum VisitOutcome {
  scheduled('scheduled', 'Planlandı'),
  completed('completed', 'Tamamlandı'),
  noShow('no_show', 'Gelmedi'),
  rescheduled('rescheduled', 'Ertelemeli'),
  cancelled('cancelled', 'İptal');

  const VisitOutcome(this.id, this.label);
  final String id;
  final String label;

  static VisitOutcome fromId(String? id) {
    if (id == null || id.isEmpty) return VisitOutcome.scheduled;
    return VisitOutcome.values.firstWhere(
      (e) => e.id == id,
      orElse: () => VisitOutcome.scheduled,
    );
  }
}

/// Ziyaret entity (Visit Intelligence).
class VisitEntity with EquatableMixin {
  const VisitEntity({
    required this.id,
    required this.customerId,
    required this.listingId,
    required this.advisorId,
    this.scheduledAt,
    this.completedAt,
    this.outcome = VisitOutcome.scheduled,
    this.notes,
    this.nextAction,
    this.autoFollowUpTaskId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String listingId;
  final String advisorId;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final VisitOutcome outcome;
  final String? notes;
  final String? nextAction;
  final String? autoFollowUpTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, updatedAt];
}
