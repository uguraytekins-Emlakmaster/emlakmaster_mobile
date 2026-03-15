import 'package:emlakmaster_mobile/features/lead_temperature_engine/domain/entities/lead_temperature_inputs.dart';
import 'package:emlakmaster_mobile/features/lead_temperature_engine/domain/usecases/compute_lead_temperature.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/shared/models/lead_temperature.dart';

/// Müşteri entity'den Lead Temperature girdileri üretir ve skor hesaplar.
class LeadTemperatureRepository {
  LeadTemperatureRepository() : _compute = ComputeLeadTemperature();

  final ComputeLeadTemperature _compute;

  LeadTemperatureInputs inputsFromCustomer(CustomerEntity c) {
    final last = c.lastInteractionAt;
    final days = last != null
        ? DateTime.now().difference(last).inDays
        : null;
    final budgetClarity = (c.budgetMin != null && c.budgetMax != null) ? 0.8 : (c.budgetMin != null || c.budgetMax != null ? 0.5 : 0.0);
    final regionClarity = c.regionPreferences.isNotEmpty ? (c.regionPreferences.length >= 2 ? 0.9 : 0.6) : 0.0;
    return LeadTemperatureInputs(
      lastContactAt: last,
      callCountLast30Days: c.callsCount,
      budgetClarityScore: budgetClarity,
      regionClarityScore: regionClarity,
      hasOffer: c.offersCount > 0,
      hasVisit: c.visitsCount > 0,
      daysSinceLastContact: days,
    );
  }

  LeadTemperatureScore computeForCustomer(CustomerEntity c) {
    return _compute.call(inputsFromCustomer(c));
  }

  LeadTemperatureLevel levelForCustomer(CustomerEntity c) {
    return computeForCustomer(c).level;
  }
}
