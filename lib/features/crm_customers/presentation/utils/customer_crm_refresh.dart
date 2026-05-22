import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_timeline_rows_provider.dart';
import 'package:emlakmaster_mobile/features/lead_temperature_engine/presentation/providers/lead_temperature_by_customer_id_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Liste ↔ detay: müşteri CRM yüzeylerini aynı veri turunda yeniler.
void invalidateCustomerCrmCascade(WidgetRef ref, String customerId) {
  if (customerId.isEmpty) return;
  ref.invalidate(customerEntityByIdProvider(customerId));
  ref.invalidate(customerInsightProvider(customerId));
  ref.invalidate(customerTimelineRowsProvider(customerId));
  ref.invalidate(customerListForAgentProvider);
  ref.invalidate(leadTemperatureByCustomerIdProvider);
}
