import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_insight_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_next_best_action.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri detayı: sıcaklık + NBA; tek görev/not sayımı (şema yok).
final customerInsightProvider =
    FutureProvider.autoDispose.family<CustomerInsightSnapshot, String>((ref, customerId) async {
  if (customerId.isEmpty) return CustomerInsightSnapshot.empty();
  final entity = await ref.watch(customerEntityByIdProvider(customerId).future);
  if (entity == null) return CustomerInsightSnapshot.empty();

  final tasks = await FirestoreService.countOpenTasksForCustomer(customerId);
  final notes = await FirestoreService.countRecentNotesForCustomer(customerId);
  final extras = CustomerHeatExtras(
    openTasksForCustomer: tasks,
    notesLast30Days: notes,
  );
  final heat = computeCustomerHeat(entity, extras: extras);
  final nextBest = computeNextBestAction(entity, heat: heat, extras: extras);

  return CustomerInsightSnapshot(
    entity: entity,
    heat: heat,
    nextBest: nextBest,
    extras: extras,
  );
});
