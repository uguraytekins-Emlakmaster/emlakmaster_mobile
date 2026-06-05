import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_sync_ui_state.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_display_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_extra_page_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_name_lookup_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Çağrılarım workspace — tek türetilmiş snapshot.
/// Mevcut veri katmanını yeniden kullanır; arama/filtre yüzeyde bellek içi.
final callsWorkspaceSnapshotProvider =
    Provider.autoDispose<AsyncValue<CallsWorkspaceSnapshot>>((ref) {
  final docsAsync = ref.watch(consultantCallsDisplayProvider);
  final localsAsync = ref.watch(localCallRecordsStreamProvider);
  final customerNames = ref.watch(customerNameLookupProvider);
  final uid =
      ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));

  if (docsAsync.isLoading &&
      !docsAsync.hasValue &&
      localsAsync.isLoading &&
      !localsAsync.hasValue) {
    return const AsyncValue.loading();
  }
  if (docsAsync.hasError && !docsAsync.hasValue) {
    return AsyncValue.error(
      docsAsync.error!,
      docsAsync.stackTrace ?? StackTrace.current,
    );
  }

  final docs = docsAsync.valueOrNull ?? const [];
  final locals = localsAsync.valueOrNull ?? const [];
  final canLoadMore = ref.watch(consultantCallsCanLoadMoreProvider);
  final extra =
      uid.isEmpty ? null : ref.watch(consultantCallsExtraPageProvider(uid));

  final firestoreIds = {
    for (final d in docs) d.id,
    for (final r in locals)
      if (r.firestoreDocumentId != null && r.firestoreDocumentId!.isNotEmpty)
        r.firestoreDocumentId!,
  };

  final inputs = <CallWorkspaceInput>[
    for (final r in locals)
      if (r.firestoreDocumentId == null ||
          r.firestoreDocumentId!.isEmpty ||
          !firestoreIds.contains(r.firestoreDocumentId))
        _inputFromLocal(r, customerNames),
    for (final d in docs) _inputFromFirestore(d, customerNames),
  ];

  final nowMs = DateTime.now().millisecondsSinceEpoch;
  var pendingLocal = 0;
  for (final r in locals) {
    final st = deriveLocalCallSyncUiState(r, nowMs: nowMs);
    if (st != LocalCallSyncUiState.synced || !r.hasQuickCapturePayload) {
      pendingLocal++;
    }
  }

  final snapshot =
      computeCallsWorkspaceSnapshot(inputs, now: DateTime.now());
  return AsyncValue.data(
    snapshot.copyWith(
      hasMore: canLoadMore || (extra?.hasMore ?? false),
      uid: uid,
      pendingLocalCount: pendingLocal,
    ),
  );
});

CallWorkspaceInput _inputFromFirestore(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
  Map<String, String> customerNames,
) {
  final data = doc.data();
  final direction = data['direction'] as String? ??
      data['callDirection'] as String? ??
      '';
  final isIncoming = direction == 'incoming';
  final rawPhone = data['phoneNumber'] as String? ??
      data['phone'] as String? ??
      '';
  final customerId = CrmCallRecordHelpers.customerIdOf(data);
  final customerName =
      customerId != null ? customerNames[customerId] : null;
  final contactName = CrmCallRecordDisplay.contactNameFromCallData(data);
  final duration = data['durationSec'] as num?;
  final outcomeCode = (data['outcome'] as String?)?.trim().isNotEmpty == true
      ? data['outcome'] as String
      : (data['callOutcome'] as String?)?.trim();
  final created = CrmCallRecordHelpers.createdAtOf(data) ?? DateTime.now();

  return CallWorkspaceInput(
    recordKey: 'fs_${doc.id}',
    sourceKind: 'firestore',
    firestoreDocId: doc.id,
    rawPhone: rawPhone,
    customerId: customerId,
    customerFullName: customerName,
    contactDisplayName: contactName,
    isIncoming: isIncoming,
    durationSec: duration?.toInt(),
    outcomeCode: outcomeCode,
    outcomeLabel: CrmCallRecordHelpers.outcomeDisplayTrDefault(data),
    createdAt: created,
    isHandoffPending: CrmCallRecordHelpers.isHandoffPending(data),
    hasCaptureCompleted: CrmCallRecordHelpers.hasCaptureCompleted(data),
    isLocalDraft: false,
    notes: data['notes'] as String?,
  );
}

CallWorkspaceInput _inputFromLocal(
  LocalCallRecord record,
  Map<String, String> customerNames,
) {
  final customerId = record.customerId;
  final customerName = customerId != null && customerId.isNotEmpty
      ? customerNames[customerId]
      : null;
  final created = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
  final oc = (record.outcome ?? '').trim();

  return CallWorkspaceInput(
    recordKey: 'local_${record.id}',
    sourceKind: 'local',
    firestoreDocId: record.firestoreDocumentId,
    rawPhone: record.phoneNumber,
    customerId: customerId,
    customerFullName: customerName,
    isIncoming: false,
    outcomeCode: oc.isEmpty ? null : oc,
    outcomeLabel: oc.isEmpty ? 'Kayıt süreci' : QuickCallOutcome.labelTr(oc),
    createdAt: created,
    isHandoffPending: oc == 'handoff_pending',
    hasCaptureCompleted: record.hasQuickCapturePayload,
    isLocalDraft: !record.isSynced || !record.hasQuickCapturePayload,
    notes: record.notes,
  );
}
