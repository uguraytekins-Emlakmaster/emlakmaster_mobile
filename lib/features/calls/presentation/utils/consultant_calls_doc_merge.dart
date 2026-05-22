import 'package:cloud_firestore/cloud_firestore.dart';

List<QueryDocumentSnapshot<Map<String, dynamic>>> mergeConsultantCallDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> primary,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> extra,
) {
  if (extra.isEmpty) return primary;
  final ids = primary.map((d) => d.id).toSet();
  final out = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(primary);
  for (final d in extra) {
    if (ids.add(d.id)) out.add(d);
  }
  out.sort((a, b) {
    final at =
        (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
    final bt =
        (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
    return bt.compareTo(at);
  });
  return out;
}
