import 'package:equatable/equatable.dart';

/// Müşteri sıcaklık seviyesi (Lead Temperature Engine çıktısı).
enum LeadTemperatureLevel {
  cold('cold', 'Soğuk', 0),
  warm('warm', 'Ilık', 1),
  hot('hot', 'Sıcak', 2),
  urgent('urgent', 'Acil', 3),
  reactivationCandidate('reactivation_candidate', 'Yeniden kazanım', 0);

  const LeadTemperatureLevel(this.id, this.label, this.sortOrder);
  final String id;
  final String label;
  final int sortOrder;

  static LeadTemperatureLevel fromId(String? id) {
    if (id == null || id.isEmpty) return LeadTemperatureLevel.cold;
    return LeadTemperatureLevel.values.firstWhere(
      (e) => e.id == id,
      orElse: () => LeadTemperatureLevel.cold,
    );
  }
}

/// Lead Temperature Engine çıktı modeli (skor + seviye).
class LeadTemperatureScore with EquatableMixin {
  const LeadTemperatureScore({
    required this.level,
    this.score = 0.0,
    this.lastComputedAt,
    this.factors,
  });

  final LeadTemperatureLevel level;
  final double score;
  final DateTime? lastComputedAt;
  final Map<String, double>? factors;

  @override
  List<Object?> get props => [level, score, lastComputedAt];
}
