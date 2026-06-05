import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/smart_matching_engine/presentation/providers/portfolio_match_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_display_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri detay workspace — tek türetilmiş snapshot (customerId).
final customerDetailWorkspaceSnapshotProvider = Provider.autoDispose
    .family<AsyncValue<CustomerDetailWorkspaceSnapshot>, String>((ref, customerId) {
  if (customerId.isEmpty) {
    return AsyncValue.data(
      computeCustomerDetailWorkspaceSnapshot(
        CustomerDetailWorkspaceInput(
          customerId: customerId,
          now: DateTime.now(),
        ),
      ),
    );
  }

  final entityAsync = ref.watch(customerEntityByIdProvider(customerId));
  final uid =
      ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  final tasksAsync =
      uid.isEmpty ? null : ref.watch(advisorTasksDisplayProvider(uid));
  final listingsAsync =
      ref.watch(topMatchedListingsForCustomerProvider(customerId));

  if (entityAsync.isLoading && !entityAsync.hasValue) {
    return const AsyncValue.loading();
  }
  if (entityAsync.hasError && !entityAsync.hasValue) {
    return AsyncValue.error(
      entityAsync.error!,
      entityAsync.stackTrace ?? StackTrace.current,
    );
  }

  final entity = entityAsync.valueOrNull;
  final openTasks = _openTasksForCustomer(
    tasksAsync?.valueOrNull,
    customerId,
  );

  final listingsLoading = listingsAsync.isLoading && !listingsAsync.hasValue;
  final matched = listingsAsync.valueOrNull
          ?.map(
            (m) => CustomerDetailListingRow(
              listingId: m.listingId,
              title: m.title,
            ),
          )
          .toList(growable: false) ??
      const <CustomerDetailListingRow>[];

  return AsyncValue.data(
    computeCustomerDetailWorkspaceSnapshot(
      CustomerDetailWorkspaceInput(
        customerId: customerId,
        entity: entity,
        openTasks: openTasks,
        matchedListings: matched,
        portfolioLoading: listingsLoading,
        now: DateTime.now(),
      ),
    ),
  );
});

List<CustomerDetailLinkedRow> _openTasksForCustomer(
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs,
  String customerId,
) {
  if (docs == null) return const [];
  final rows = <CustomerDetailLinkedRow>[];
  for (final doc in docs) {
    final data = doc.data();
    final cid = (data['customerId'] as String?)?.trim();
    if (cid != customerId) continue;
    final done = data['done'] == true || data['completed'] == true;
    if (done) continue;
    final title = (data['title'] as String?)?.trim();
    rows.add(
      CustomerDetailLinkedRow(
        id: doc.id,
        title: title != null && title.isNotEmpty ? title : 'Görev',
        statusLabel: _taskStatusLabel(data),
        nextActionLabel: 'Görev detayı',
      ),
    );
  }
  return rows;
}

String _taskStatusLabel(Map<String, dynamic> data) {
  final dueRaw = data['dueAt'] ?? data['dueDate'];
  DateTime? dueAt;
  if (dueRaw is Timestamp) {
    dueAt = dueRaw.toDate();
  } else if (dueRaw is DateTime) {
    dueAt = dueRaw;
  }
  if (dueAt == null) return 'Vade yok';
  final now = DateTime.now();
  if (dueAt.isBefore(DateTime(now.year, now.month, now.day))) {
    return 'Geciken';
  }
  if (dueAt.year == now.year &&
      dueAt.month == now.month &&
      dueAt.day == now.day) {
    return 'Bugün';
  }
  return 'Açık';
}
