import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_list_heat_filter.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_test/flutter_test.dart';

CustomerEntity _entity(String id) => CustomerEntity(
      id: id,
      fullName: 'Test',
      updatedAt: DateTime(2024),
      createdAt: DateTime(2024),
    );

CustomerListRowSnapshot _snapshot({
  CustomerHeatLevel level = CustomerHeatLevel.warm,
  RevenueLeadBand? band,
}) {
  return CustomerListRowSnapshot(
    crmHeat: CustomerHeatSnapshot(
      heatLevel: level,
      heatScore: 55,
      heatReasonSummary: 'test',
    ),
    showBrokerAlert: false,
    syncDelayedRisk: false,
    revenueSignal: band == null
        ? null
        : CustomerRevenueSignals(
            customerId: 'x',
            leadScore: 60,
            band: band,
            valueScore: 1,
            nextAction: RevenueNextActionKind.call,
            nextActionTime: DateTime(2024),
            recommendationSuppressed: true,
            syncDelayedRisk: false,
          ),
  );
}

void main() {
  test('applyCustomerHeatFilter respects revenue band', () {
    final entities = [_entity('a'), _entity('b')];
    final snapshots = {
      'a': _snapshot(band: RevenueLeadBand.hot),
      'b': _snapshot(level: CustomerHeatLevel.cold),
    };
    final hotOnly = applyCustomerHeatFilter(
      entities: entities,
      snapshots: snapshots,
      filter: CustomerListHeatFilter.hot,
    );
    expect(hotOnly, hasLength(1));
    expect(hotOnly.first.id, 'a');
  });
}
