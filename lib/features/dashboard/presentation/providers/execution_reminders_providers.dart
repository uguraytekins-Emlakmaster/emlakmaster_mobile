import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/data/execution_reminder_dedupe_store.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/execution_reminder.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_wide_customers_stream_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final executionReminderDedupeStoreProvider =
    Provider<ExecutionReminderDedupeStore>((ref) => ExecutionReminderDedupeStore());

/// Danışman: atanmış müşteriler üzerinden hatırlatıcılar.
final consultantExecutionRemindersProvider =
    FutureProvider.autoDispose<List<ExecutionReminderItem>>((ref) async {
  final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  if (uid.isEmpty) return [];
  final async = ref.watch(customerListForAgentProvider);
  return async.when(
    data: (customers) async {
      final raw = aggregateExecutionReminders(customers);
      final store = ref.read(executionReminderDedupeStoreProvider);
      final out = <ExecutionReminderItem>[];
      for (final r in raw) {
        if (await store.isSuppressed(uid, r.dedupeKey)) continue;
        out.add(r);
      }
      return out;
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});

/// Broker / yönetici: ofis müşterileri; orta öncelik satırları filtrelenir.
final brokerExecutionRemindersProvider =
    FutureProvider.autoDispose<List<ExecutionReminderItem>>((ref) async {
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
      final raw = aggregateExecutionReminders(customers, maxItems: 18, teamScope: true);
      final store = ref.read(executionReminderDedupeStoreProvider);
      final out = <ExecutionReminderItem>[];
      for (final r in raw) {
        if (await store.isSuppressed(uid, r.dedupeKey)) continue;
        out.add(r);
      }
      return out;
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});
