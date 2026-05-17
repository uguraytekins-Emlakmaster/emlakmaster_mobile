import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:emlakmaster_mobile/shared/models/lead_temperature.dart';

/// Müşteri listesi satırı için önceden hesaplanmış görünüm verisi.
/// Liste gövdesi tek provider ile beslenir; kart başına Riverpod dinleyicisi yok.
class CustomerListRowSnapshot {
  const CustomerListRowSnapshot({
    required this.temperatureScore,
    required this.showBrokerAlert,
    required this.syncDelayedRisk,
    this.revenueSignal,
  });

  final LeadTemperatureScore temperatureScore;
  final bool showBrokerAlert;
  final bool syncDelayedRisk;
  final CustomerRevenueSignals? revenueSignal;
}
