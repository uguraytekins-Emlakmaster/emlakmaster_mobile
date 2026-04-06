import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';

/// valueScore = leadScore + çağrı yoğunluğu + recency (0–30).
int computeValueScore({
  required int leadScore,
  required int firestoreCallCount,
  required DateTime? lastContactAt,
  required DateTime now,
}) {
  final engagement = (firestoreCallCount.clamp(0, 10)) * 2;
  var recency = 0;
  final last = lastContactAt;
  if (last != null) {
    final days = now.difference(last).inDays;
    if (days <= 1) {
      recency = 30;
    } else if (days <= 7) {
      recency = 20;
    } else if (days <= 30) {
      recency = 10;
    }
  }
  final raw = leadScore + engagement + recency;
  if (raw > 200) return 200;
  return raw;
}

/// Tekilleştirilmiş müşteri ID’sine göre sırala (yüksek valueScore önce).
List<CustomerRevenueRow> rankByValueScore(List<CustomerRevenueRow> rows) {
  final byId = <String, CustomerRevenueRow>{};
  for (final row in rows) {
    byId[row.customerId] = row;
  }
  final list = byId.values.toList();
  list.sort((a, b) {
    final va = a.valueScore;
    final vb = b.valueScore;
    if (vb != va) return vb.compareTo(va);
    return b.leadScore.compareTo(a.leadScore);
  });
  return list;
}
