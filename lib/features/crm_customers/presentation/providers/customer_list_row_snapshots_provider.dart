import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_filtered_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/sync_delayed_risk_customer_ids_provider.dart';
import 'package:emlakmaster_mobile/features/lead_temperature_engine/presentation/providers/lead_temperature_by_customer_id_provider.dart';
import 'package:emlakmaster_mobile/features/lead_temperature_engine/presentation/providers/lead_temperature_provider.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/shared/models/lead_temperature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filtrelenmiş liste için id → satır snapshot (tek rebuild alanı).
final customerListRowSnapshotsProvider = Provider.autoDispose
    .family<Map<String, CustomerListRowSnapshot>, String>((ref, searchQueryLower) {
  final filtered = ref.watch(customerListFilteredProvider(searchQueryLower));
  if (filtered.isEmpty) return const {};

  final temperatures = ref.watch(leadTemperatureByCustomerIdProvider);
  final revenue = ref.watch(customerRevenueSignalsMapProvider);
  final syncRisk = ref.watch(syncDelayedRiskCustomerIdsProvider);
  final managerTier =
      (ref.watch(displayRoleOrNullProvider) ?? AppRole.guest).isManagerTier;
  final repo = ref.read(leadTemperatureRepositoryProvider);

  LeadTemperatureScore scoreFor(CustomerEntity c) =>
      temperatures[c.id] ?? repo.computeForCustomer(c);

  return {
    for (final c in filtered)
      c.id: CustomerListRowSnapshot(
        temperatureScore: scoreFor(c),
        showBrokerAlert: managerTier && brokerAlertsActiveForCustomer(c),
        syncDelayedRisk:
            revenue[c.id]?.syncDelayedRisk ?? syncRisk.contains(c.id),
        revenueSignal: revenue[c.id],
      ),
  };
});
