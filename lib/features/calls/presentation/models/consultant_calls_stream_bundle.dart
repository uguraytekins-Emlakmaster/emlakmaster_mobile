import 'package:cloud_firestore/cloud_firestore.dart';

/// Danışman çağrı stream'i: birleşik liste + sayfalama imleri.
class ConsultantCallsStreamBundle {
  const ConsultantCallsStreamBundle({
    required this.docs,
    this.hasMoreAdvisor = false,
    this.hasMoreAgent = false,
    this.lastAdvisorDoc,
    this.lastAgentDoc,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final bool hasMoreAdvisor;
  final bool hasMoreAgent;
  final DocumentSnapshot<Map<String, dynamic>>? lastAdvisorDoc;
  final DocumentSnapshot<Map<String, dynamic>>? lastAgentDoc;

  bool get hasMore => hasMoreAdvisor || hasMoreAgent;

  static const empty = ConsultantCallsStreamBundle(docs: []);
}
