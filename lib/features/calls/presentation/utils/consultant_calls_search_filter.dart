import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';

/// Danışman çağrı geçmişi — istemci tarafı arama (Firestore + yerel taslak).
abstract final class ConsultantCallsSearchFilter {
  ConsultantCallsSearchFilter._();

  static bool matchesFirestoreDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String queryLower,
    Map<String, String> customerNames,
  ) {
    if (queryLower.isEmpty) return true;
    final data = doc.data();
    final phone = ((data['phoneNumber'] ?? data['phone']) ?? '')
        .toString()
        .toLowerCase();
    final outcomeRaw =
        data['outcome'] as String? ?? data['callOutcome'] as String? ?? '';
    final outcomeLabel = outcomeRaw.isNotEmpty
        ? (CrmCallRecordHelpers.kOutcomeCodeLabelsTr[outcomeRaw] ?? outcomeRaw)
            .toLowerCase()
        : '';
    final note = (data['quickCaptureNote'] as String? ??
            data['notes'] as String? ??
            '')
        .toLowerCase();
    final ql = (data['quickOutcomeLabelTr'] as String? ?? '').toLowerCase();
    final contactName =
        (CrmCallRecordDisplay.contactNameFromCallData(data) ?? '').toLowerCase();
    final cid = CrmCallRecordHelpers.customerIdOf(data);
    final custName =
        cid != null ? (customerNames[cid] ?? '').toLowerCase() : '';
    return phone.contains(queryLower) ||
        outcomeLabel.contains(queryLower) ||
        note.contains(queryLower) ||
        ql.contains(queryLower) ||
        contactName.contains(queryLower) ||
        custName.contains(queryLower);
  }

  static bool matchesLocalRecord(
    LocalCallRecord record,
    String queryLower,
    Map<String, String> customerNames,
  ) {
    if (queryLower.isEmpty) return true;
    final phone = record.phoneNumber.toLowerCase();
    final outcome = (record.outcome ?? '').toLowerCase();
    final notes = (record.notes ?? '').toLowerCase();
    final cust = record.customerId != null
        ? (customerNames[record.customerId!] ?? '').toLowerCase()
        : '';
    return phone.contains(queryLower) ||
        outcome.contains(queryLower) ||
        notes.contains(queryLower) ||
        cust.contains(queryLower);
  }
}
