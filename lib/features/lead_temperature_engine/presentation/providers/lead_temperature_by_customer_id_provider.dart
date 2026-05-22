import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/lead_temperature_engine/presentation/providers/lead_temperature_provider.dart';
import 'package:emlakmaster_mobile/shared/models/lead_temperature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman müşteri listesi için toplu sıcaklık skorları (kart başına family yok).
final leadTemperatureByCustomerIdProvider =
    Provider.autoDispose<Map<String, LeadTemperatureScore>>((ref) {
  final customers = ref.watch(customerListEntitiesProvider);
  if (customers.isEmpty) return const {};
  final repo = ref.watch(leadTemperatureRepositoryProvider);
  return {
    for (final c in customers)
      if (c.id.isNotEmpty) c.id: repo.computeForCustomer(c),
  };
});
