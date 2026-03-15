import 'package:equatable/equatable.dart';

/// Pipeline öğesi / satış sağlık seviyesi.
enum DealHealthLevel {
  healthy('healthy', 'Sağlıklı', 3),
  watch('watch', 'İzle', 2),
  risk('risk', 'Risk', 1),
  critical('critical', 'Kritik', 0);

  const DealHealthLevel(this.id, this.label, this.sortOrder);
  final String id;
  final String label;
  final int sortOrder;

  static DealHealthLevel fromId(String? id) {
    if (id == null || id.isEmpty) return DealHealthLevel.healthy;
    return DealHealthLevel.values.firstWhere(
      (e) => e.id == id,
      orElse: () => DealHealthLevel.healthy,
    );
  }
}

/// Deal Health + kapanma ihtimali (Rainbow Predict).
class DealHealthScore with EquatableMixin {
  const DealHealthScore({
    required this.level,
    this.closeProbabilityPercent,
    this.lastComputedAt,
    this.factors,
  });

  final DealHealthLevel level;
  final double? closeProbabilityPercent;
  final DateTime? lastComputedAt;
  final Map<String, double>? factors;

  @override
  List<Object?> get props => [level, closeProbabilityPercent, lastComputedAt];
}
