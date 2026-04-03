import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/data/task_suggestion_dedupe_store.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/smart_task_suggestion.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_wide_customers_stream_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taskSuggestionDedupeStoreProvider =
    Provider<TaskSuggestionDedupeStore>((ref) => TaskSuggestionDedupeStore());

/// Broker dashboard: görev önerileri (sessiz yazım yok; bastırılanlar filtrelenir).
final brokerSmartTaskSuggestionsProvider =
    FutureProvider.autoDispose<List<SmartTaskSuggestion>>((ref) async {
  final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
  if (!role.isManagerTier) return [];
  final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  if (uid.isEmpty) return [];
  final officeId =
      ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId ?? '';
  if (officeId.isEmpty) return [];
  final async = ref.watch(officeWideCustomerListProvider(officeId));
  return async.when(
    data: (customers) async {
      final raw = aggregateSmartTaskSuggestions(customers, fallbackAdvisorId: uid);
      final store = ref.read(taskSuggestionDedupeStoreProvider);
      final out = <SmartTaskSuggestion>[];
      for (final s in raw) {
        if (await store.isSuppressed(uid, s.dedupeKey)) continue;
        out.add(s);
      }
      return out;
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});

/// Müşteri detay (yönetici): tek birincil öneri veya null.
final customerSmartTaskSuggestionProvider =
    FutureProvider.autoDispose.family<SmartTaskSuggestion?, String>((ref, customerId) async {
  final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
  if (!role.isManagerTier) return null;
  final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  if (uid.isEmpty || customerId.isEmpty) return null;
  final entity = ref.watch(customerEntityByIdProvider(customerId)).valueOrNull;
  if (entity == null) return null;
  final alerts = computeBrokerAlertsForCustomer(entity);
  if (alerts.isEmpty) return null;
  final store = ref.read(taskSuggestionDedupeStoreProvider);
  for (final a in alerts) {
    final s = smartTaskSuggestionFromAlert(a, entity, uid);
    if (!await store.isSuppressed(uid, s.dedupeKey)) return s;
  }
  return null;
});
