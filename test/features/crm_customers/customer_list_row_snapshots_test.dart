import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_filtered_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_row_snapshots_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/sync_delayed_risk_customer_ids_provider.dart';
import 'package:emlakmaster_mobile/features/lead_temperature_engine/presentation/providers/lead_temperature_by_customer_id_provider.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CustomerEntity _entity(String id, {String? name}) {
  return CustomerEntity(
    id: id,
    fullName: name ?? 'Test $id',
    primaryPhone: '+905551112233',
    updatedAt: DateTime(2024, 1, 1),
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  test('customerListRowSnapshotsProvider builds entry per filtered id', () async {
    final container = ProviderContainer(
      overrides: [
        customerListForAgentProvider.overrideWith(
          (ref) => Stream.value([
            _entity('a'),
            _entity('b', name: 'Ayşe'),
          ]),
        ),
        syncDelayedRiskCustomerIdsProvider.overrideWith((ref) => {'a'}),
        customerRevenueSignalsMapProvider.overrideWith((ref) => const {}),
        leadTemperatureByCustomerIdProvider.overrideWith((ref) => const {}),
      ],
    );
    addTearDown(container.dispose);

    await container.read(customerListForAgentProvider.future);

    final filtered =
        container.read(customerListFilteredProvider('ayşe'));
    expect(filtered, hasLength(1));
    expect(filtered.first.id, 'b');

    final snapshots =
        container.read(customerListRowSnapshotsProvider('ayşe'));
    expect(snapshots.containsKey('b'), isTrue);
    expect(snapshots['b']!.syncDelayedRisk, isFalse);
  });
}
