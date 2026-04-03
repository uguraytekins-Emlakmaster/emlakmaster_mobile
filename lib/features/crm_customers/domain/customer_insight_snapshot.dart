import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_next_best_action.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Sıcaklık + sonraki aksiyon (tek okuma yolunda üretilir).
class CustomerInsightSnapshot {
  const CustomerInsightSnapshot({
    required this.entity,
    required this.heat,
    required this.nextBest,
    required this.extras,
  });

  final CustomerEntity? entity;
  final CustomerHeatSnapshot heat;
  final NextBestActionSnapshot nextBest;
  final CustomerHeatExtras extras;

  static CustomerInsightSnapshot empty() => CustomerInsightSnapshot(
        entity: null,
        heat: CustomerHeatSnapshot.empty(),
        nextBest: NextBestActionSnapshot.fallback(),
        extras: const CustomerHeatExtras(),
      );
}
