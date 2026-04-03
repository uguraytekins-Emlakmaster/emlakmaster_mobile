import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_wide_customers_stream_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yönetici / broker: ofis müşteri akışı üzerinden uyarılar (ek sorgu yok).
final brokerDashboardAlertsProvider =
    Provider.autoDispose<AsyncValue<List<BrokerCustomerAlertItem>>>((ref) {
  final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
  if (!role.isManagerTier) {
    return const AsyncValue.data([]);
  }
  final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  if (uid.isEmpty) {
    return const AsyncValue.data([]);
  }
  final officeId =
      ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId ?? '';
  if (officeId.isEmpty) {
    return const AsyncValue.data([]);
  }
  final async = ref.watch(officeWideCustomerListProvider(officeId));
  return async.when(
    data: (customers) => AsyncValue.data(aggregateBrokerAlerts(customers)),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
