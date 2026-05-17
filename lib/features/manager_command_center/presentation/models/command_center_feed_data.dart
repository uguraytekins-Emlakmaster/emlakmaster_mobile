import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';

/// Komuta merkezi beslemesi — filtre sonrası paylaşılan bağlam.
class CommandCenterFeedData {
  const CommandCenterFeedData({
    required this.docs,
    required this.filtered,
    required this.agentNames,
    required this.locals,
    required this.currentUid,
    required this.customerFullNameById,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered;
  final Map<String, String> agentNames;
  final List<LocalCallRecord> locals;
  final String? currentUid;
  final Map<String, String> customerFullNameById;
}
