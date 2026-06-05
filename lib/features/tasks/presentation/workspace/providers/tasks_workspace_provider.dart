import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_name_lookup_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_display_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasksWorkspaceSnapshotProvider =
    Provider.autoDispose<AsyncValue<TasksWorkspaceSnapshot>>((ref) {
  final uid =
      ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  if (uid.isEmpty) {
    return const AsyncValue.data(
      TasksWorkspaceSnapshot(
        rows: [],
        overdueRows: [],
        quickCloseRows: [],
        summary: TasksWorkspaceSummary.empty,
        coverageNote: '',
        isEmpty: true,
        dateChipLabel: '',
      ),
    );
  }

  final tasksAsync = ref.watch(advisorTasksDisplayProvider(uid));
  final customerNames = ref.watch(customerNameLookupProvider);

  if (tasksAsync.isLoading && !tasksAsync.hasValue) {
    return const AsyncValue.loading();
  }
  if (tasksAsync.hasError && !tasksAsync.hasValue) {
    return AsyncValue.error(
      tasksAsync.error!,
      tasksAsync.stackTrace ?? StackTrace.current,
    );
  }

  final docs = tasksAsync.valueOrNull ?? const [];
  final inputs = [
    for (final doc in docs) _inputFromDoc(doc, customerNames),
  ];

  final snapshot =
      computeTasksWorkspaceSnapshot(inputs, now: DateTime.now());
  return AsyncValue.data(snapshot.copyWith(uid: uid));
});

TaskWorkspaceInput _inputFromDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
  Map<String, String> customerNames,
) {
  final data = doc.data();
  final customerId = (data['customerId'] as String?)?.trim();
  final customerName =
      customerId != null && customerId.isNotEmpty
          ? customerNames[customerId]
          : null;
  final phone = data['customerPhone'] as String?;
  final callable = phone != null &&
      phone.trim().isNotEmpty &&
      OutboundPhoneDial.isLikelyCallablePhone(phone);

  return TaskWorkspaceInput(
    id: doc.id,
    title: data['title'] as String? ?? '',
    done: taskDocIsDone(data),
    dueAt: taskDocDueAt(data),
    customerId: customerId,
    customerName: customerName,
    phone: phone?.trim(),
    callablePhone: callable,
    recurrence: data['recurrence'] as String?,
    rawData: data,
  );
}
