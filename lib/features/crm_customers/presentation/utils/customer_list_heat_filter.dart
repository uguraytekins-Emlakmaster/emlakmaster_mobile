import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Müşteri listesi — istemci tarafı sıcaklık filtresi (yeni backend yok).
enum CustomerListHeatFilter {
  all,
  hot,
  warm,
  cold,
}

extension CustomerListHeatFilterLabels on CustomerListHeatFilter {
  String get labelTr => switch (this) {
        CustomerListHeatFilter.all => 'Tümü',
        CustomerListHeatFilter.hot => 'Sıcak',
        CustomerListHeatFilter.warm => 'Ilık',
        CustomerListHeatFilter.cold => 'Soğuk',
      };
}

bool customerMatchesHeatFilter(
  CustomerEntity entity,
  CustomerListRowSnapshot row,
  CustomerListHeatFilter filter,
) {
  if (filter == CustomerListHeatFilter.all) return true;
  final band = _resolvedBand(entity, row);
  return switch (filter) {
    CustomerListHeatFilter.hot => band == _HeatBand.hot,
    CustomerListHeatFilter.warm => band == _HeatBand.warm,
    CustomerListHeatFilter.cold =>
      band == _HeatBand.cool || band == _HeatBand.cold,
    CustomerListHeatFilter.all => true,
  };
}

enum _HeatBand { hot, warm, cool, cold }

_HeatBand _resolvedBand(CustomerEntity entity, CustomerListRowSnapshot row) {
  final revenue = row.revenueSignal?.band;
  if (revenue != null) {
    return switch (revenue) {
      RevenueLeadBand.hot => _HeatBand.hot,
      RevenueLeadBand.warm => _HeatBand.warm,
      RevenueLeadBand.cold => _HeatBand.cold,
    };
  }
  final temp = entity.leadTemperature;
  if (temp != null) {
    if (temp >= 0.7) return _HeatBand.hot;
    if (temp >= 0.4) return _HeatBand.warm;
    if (temp >= 0.2) return _HeatBand.cool;
    return _HeatBand.cold;
  }
  return switch (row.crmHeat.heatLevel) {
    CustomerHeatLevel.hot => _HeatBand.hot,
    CustomerHeatLevel.warm => _HeatBand.warm,
    CustomerHeatLevel.cool => _HeatBand.cool,
    CustomerHeatLevel.cold => _HeatBand.cold,
  };
}

List<CustomerEntity> applyCustomerHeatFilter({
  required List<CustomerEntity> entities,
  required Map<String, CustomerListRowSnapshot> snapshots,
  required CustomerListHeatFilter filter,
}) {
  if (filter == CustomerListHeatFilter.all) return entities;
  return [
    for (final e in entities)
      if (snapshots[e.id] != null &&
          customerMatchesHeatFilter(e, snapshots[e.id]!, filter))
        e,
  ];
}
