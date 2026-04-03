import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/data/escalation_dedupe_store.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_wide_customers_stream_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final escalationDedupeStoreProvider =
    Provider<EscalationDedupeStore>((ref) => EscalationDedupeStore());

/// Yönetici taşımaları — push yok; dashboard bölümü (dedupe sonrası).
final managerEscalationsProvider =
    FutureProvider.autoDispose<List<ManagerEscalationItem>>((ref) async {
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
      final raw = aggregatePrimaryEscalations(customers);
      final store = ref.read(escalationDedupeStoreProvider);
      final out = <ManagerEscalationItem>[];
      for (final e in raw) {
        if (await store.isSuppressed(uid, e.dedupeKey)) continue;
        out.add(e);
      }
      return out;
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});
