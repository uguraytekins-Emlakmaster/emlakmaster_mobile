import 'package:emlakmaster_mobile/features/lead_temperature_engine/data/lead_temperature_repository.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/shared/models/lead_temperature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leadTemperatureRepositoryProvider = Provider<LeadTemperatureRepository>((ref) {
  return LeadTemperatureRepository();
});

/// Tek bir müşteri için sıcaklık skoru.
final leadTemperatureForCustomerProvider =
    Provider.family<LeadTemperatureScore, CustomerEntity>((ref, customer) {
  final repo = ref.watch(leadTemperatureRepositoryProvider);
  return repo.computeForCustomer(customer);
});

/// Müşteri için sadece seviye (liste/kartlarda göstermek için).
final leadTemperatureLevelProvider =
    Provider.family<LeadTemperatureLevel, CustomerEntity>((ref, customer) {
  final repo = ref.watch(leadTemperatureRepositoryProvider);
  return repo.levelForCustomer(customer);
});
