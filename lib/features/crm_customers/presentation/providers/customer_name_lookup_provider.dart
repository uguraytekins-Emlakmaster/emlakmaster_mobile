import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Çağrı listesi için hafif id → isim haritası (tam [CustomerEntity] listesi yerine).
final customerNameLookupProvider =
    Provider.autoDispose<Map<String, String>>((ref) {
  final customers = ref.watch(customerListEntitiesProvider);
  if (customers.isEmpty) return const {};
  return {
    for (final c in customers)
      if (c.id.isNotEmpty) c.id: (c.fullName ?? '').trim(),
  };
});
