import 'package:emlakmaster_mobile/features/calls/domain/customer_sync_delayed_risk.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Senkronu gecikmiş olabilecek müşteri ID’leri (yerel Hive çağrı kayıtlarına göre).
final syncDelayedRiskCustomerIdsProvider =
    Provider.autoDispose<Set<String>>((ref) {
  final locals = ref.watch(localCallRecordsStreamProvider).valueOrNull ?? [];
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  return customerIdsWithSyncDelayedRisk(locals, nowMs: nowMs);
});
