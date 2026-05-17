import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/sync_delayed_risk_customer_ids_provider.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arama + risk sıralaması — liste gövdesi tek [SliverList] için önceden hesaplanır.
final customerListFilteredProvider =
    Provider.autoDispose.family<List<CustomerEntity>, String>((ref, searchQueryLower) {
  final entities = ref.watch(customerListForAgentProvider).valueOrNull;
  if (entities == null || entities.isEmpty) return const [];

  final q = searchQueryLower;
  final filtered = q.isEmpty
      ? List<CustomerEntity>.from(entities)
      : entities.where((e) {
          final name = (e.fullName ?? '').toLowerCase();
          final phone =
              (e.primaryPhone ?? '').replaceAll(RegExp(r'\s'), '');
          final email = (e.email ?? '').toLowerCase();
          final queryNoSpaces = q.replaceAll(RegExp(r'\s'), '');
          return name.contains(q) ||
              email.contains(q) ||
              phone.contains(queryNoSpaces) ||
              (queryNoSpaces.isNotEmpty && phone.contains(queryNoSpaces));
        }).toList();

  if (filtered.length > 1) {
    final riskIds = ref.watch(syncDelayedRiskCustomerIdsProvider);
    filtered.sort((a, b) {
      final ar = riskIds.contains(a.id);
      final br = riskIds.contains(b.id);
      if (ar != br) return ar ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }
  return filtered;
});
