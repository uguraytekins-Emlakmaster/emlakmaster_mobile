import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_wide_customers_stream_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ofis geneli müşteri id → tam ad (Komuta Merkezi çağrı başlıkları).
final officeCustomerNameLookupProvider =
    Provider.autoDispose.family<Map<String, String>, String>((ref, officeId) {
  if (officeId.isEmpty) return const {};
  final entities =
      ref.watch(officeWideCustomerListProvider(officeId)).valueOrNull;
  if (entities == null || entities.isEmpty) return const {};
  return {
    for (final c in entities)
      if (c.id.isNotEmpty && (c.fullName?.trim().isNotEmpty ?? false))
        c.id: c.fullName!.trim(),
  };
});
