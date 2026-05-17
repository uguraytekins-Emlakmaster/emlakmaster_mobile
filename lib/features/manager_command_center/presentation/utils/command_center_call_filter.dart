import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_feed_filters.dart';

/// Firestore çağrı dokümanlarını Komuta Merkezi filtrelerine göre süzer (saf fonksiyon).
List<QueryDocumentSnapshot<Map<String, dynamic>>> filterCommandCenterCalls({
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  required CommandCenterFeedFilters filters,
  required Map<String, String> customerFullNameById,
}) {
  final q = filters.searchQueryLower;
  return docs.where((d) {
    final data = d.data();
    final agentId = CrmCallRecordHelpers.agentIdOf(data);
    if (filters.filterTeamId != null &&
        filters.teamMemberIds.isNotEmpty &&
        !filters.teamMemberIds.contains(agentId)) {
      return false;
    }
    if (filters.filterAgentId != null && agentId != filters.filterAgentId) {
      return false;
    }
    if (filters.filterOutcome != null &&
        (data['outcome'] as String? ?? data['callOutcome'] as String?) !=
            filters.filterOutcome) {
      return false;
    }
    if (!CallSurfaceQuickFilterLogic.matchesFirestoreDoc(
      d,
      filters.quickFilter,
    )) {
      return false;
    }
    if (q.isEmpty) return true;

    final id = d.id.toLowerCase();
    final phone = ((data['phoneNumber'] ?? data['phone']) ?? '')
        .toString()
        .toLowerCase();
    final outcomeRaw =
        data['outcome'] as String? ?? data['callOutcome'] as String? ?? '';
    final outcomeLabel = outcomeRaw.isNotEmpty
        ? (CrmCallRecordHelpers.kOutcomeCodeLabelsTr[outcomeRaw] ?? outcomeRaw)
            .toLowerCase()
        : '';
    final cust = (data['customerId'] as String? ?? '').toLowerCase();
    final note = (data['quickCaptureNote'] as String? ?? '').toLowerCase();
    final ql = (data['quickOutcomeLabelTr'] as String? ?? '').toLowerCase();
    final contactName =
        (CrmCallRecordDisplay.contactNameFromCallData(data) ?? '').toLowerCase();
    final cidSearch = CrmCallRecordHelpers.customerIdOf(data);
    final custResolved = cidSearch != null
        ? (customerFullNameById[cidSearch] ?? '').toLowerCase()
        : '';
    return id.contains(q) ||
        agentId.toLowerCase().contains(q) ||
        phone.contains(q) ||
        outcomeLabel.contains(q) ||
        cust.contains(q) ||
        note.contains(q) ||
        ql.contains(q) ||
        contactName.contains(q) ||
        custResolved.contains(q);
  }).toList();
}
