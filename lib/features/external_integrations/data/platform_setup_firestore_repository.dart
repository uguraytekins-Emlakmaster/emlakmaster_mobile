import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/integration_platform_id.dart';
import '../domain/platform_setup_record.dart';

/// Kalıcı platform kurulum kayıtları: `offices/{officeId}/platform_setups/{platform.storageKey}`.
class PlatformSetupFirestoreRepository {
  PlatformSetupFirestoreRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _collection(String officeId) =>
      _db.collection('offices').doc(officeId).collection('platform_setups');

  DocumentReference<Map<String, dynamic>> _doc(String officeId, IntegrationPlatformId platform) =>
      _collection(officeId).doc(platform.storageKey);

  Stream<Map<IntegrationPlatformId, PlatformSetupRecord>> watchMap(String officeId) {
    if (officeId.isEmpty) {
      return Stream.value(<IntegrationPlatformId, PlatformSetupRecord>{});
    }
    return _collection(officeId).snapshots().map((snap) {
      final map = <IntegrationPlatformId, PlatformSetupRecord>{};
      for (final doc in snap.docs) {
        final r = PlatformSetupRecord.fromFirestore(doc);
        if (r != null) {
          map[r.platform] = r;
        }
      }
      return map;
    });
  }

  Future<PlatformSetupRecord?> get(String officeId, IntegrationPlatformId platform) async {
    if (officeId.isEmpty) return null;
    final doc = await _doc(officeId, platform).get();
    if (!doc.exists) return null;
    return PlatformSetupRecord.fromFirestore(doc);
  }

  Future<void> upsert(PlatformSetupRecord record) async {
    await _doc(record.officeId, record.platform).set(record.toFirestore());
  }
}
