import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `agents` koleksiyonundan danışman görünen adları (id → displayName).
final firestoreAgentDisplayNamesProvider =
    StreamProvider.autoDispose<Map<String, String>>((ref) {
  return FirestoreService.agentsStream().map((snap) {
    return {
      for (final d in snap.docs)
        d.id: () {
          final raw = d.data()['displayName'] as String?;
          final t = raw?.trim();
          if (t != null && t.isNotEmpty) return t;
          return d.id;
        }(),
    };
  });
});
