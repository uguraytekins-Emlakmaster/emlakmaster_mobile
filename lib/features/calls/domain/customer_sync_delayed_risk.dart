import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';

/// Yerel çağrı satırı bu süreden uzun süredir senkron olmadıysa müşteri “gecikme riski”.
const int kCustomerSyncDelayedRiskThresholdMs = 5 * 60 * 1000;

/// [sync_delayed_risk]: yerel kayıt var, henüz `isSynced` değil, eşik aşıldı.
bool isLocalCallSyncDelayedRisk(
  LocalCallRecord r, {
  required int nowMs,
}) {
  if (r.isSynced) return false;
  final cid = r.customerId?.trim();
  if (cid == null || cid.isEmpty) return false;
  return nowMs - r.createdAt > kCustomerSyncDelayedRiskThresholdMs;
}

/// Etkilenen Firestore müşteri kimlikleri (tekrarsız).
Set<String> customerIdsWithSyncDelayedRisk(
  Iterable<LocalCallRecord> locals, {
  required int nowMs,
}) {
  final out = <String>{};
  for (final r in locals) {
    if (!isLocalCallSyncDelayedRisk(r, nowMs: nowMs)) continue;
    out.add(r.customerId!.trim());
  }
  return out;
}
