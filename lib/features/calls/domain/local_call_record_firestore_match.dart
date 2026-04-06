import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';

/// Bu cihazdaki Hive kayıtları ile Firestore `calls` dokümanını eşleştirir.
///
/// 1) `firestoreDocumentId == docId`
/// 2) Aynı danışman + telefon + dakika (`dedupeKeyMinute` ile uyumlu)
LocalCallRecord? matchLocalCallRecordForFirestoreDoc({
  required List<LocalCallRecord> locals,
  required String docId,
  required Map<String, dynamic> data,
}) {
  final advisorId = CrmCallRecordHelpers.agentIdOf(data);
  if (advisorId.isEmpty) return null;

  for (final r in locals) {
    if (r.agentId != advisorId) continue;
    final fid = r.firestoreDocumentId;
    if (fid != null && fid == docId) return r;
  }

  final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString().trim();
  if (phone.isEmpty) return null;
  final created = CrmCallRecordHelpers.createdAtOf(data);
  if (created == null) return null;
  final docMinute = created.millisecondsSinceEpoch ~/ 60000;

  for (final r in locals) {
    if (r.agentId != advisorId) continue;
    if (r.phoneNumber.trim() != phone) continue;
    if (r.createdAt ~/ 60000 == docMinute) return r;
  }
  return null;
}
