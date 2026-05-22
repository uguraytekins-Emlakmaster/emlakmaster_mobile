import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';

/// Müşteri listesi satırı için önceden hesaplanmış görünüm verisi.
/// Liste gövdesi tek provider ile beslenir; kart başına Riverpod dinleyicisi yok.
class CustomerListRowSnapshot {
  const CustomerListRowSnapshot({
    required this.crmHeat,
    required this.showBrokerAlert,
    required this.syncDelayedRisk,
    this.revenueSignal,
  });

  /// Detay ekranı [computeCustomerHeat] ile aynı motor (extras=0; görev/not detayda).
  final CustomerHeatSnapshot crmHeat;
  final bool showBrokerAlert;
  final bool syncDelayedRisk;
  final CustomerRevenueSignals? revenueSignal;
}
