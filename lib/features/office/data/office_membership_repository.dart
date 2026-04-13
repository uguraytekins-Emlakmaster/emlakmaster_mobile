import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/office_membership_entity.dart';

class OfficeMembershipRepository {
  OfficeMembershipRepository._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String get _col => AppConstants.colOfficeMemberships;

  /// Aktif üyelik: `userId` + `status==active` (tek aktif ofis varsayımı).
  /// `users.officeId` ile aynı birincil üyelik dokümanı (`{uid}_{officeId}`).
  /// Tutarlılık ve yaşam döngüsü (invited/suspended/removed) için tek kaynak.
  static Stream<OfficeMembership?> watchPrimaryMembershipForUser(
    String userId,
    String? officeIdFromUserDoc,
  ) {
    if (officeIdFromUserDoc == null || officeIdFromUserDoc.isEmpty) {
      return Stream<OfficeMembership?>.value(null);
    }
    final docId = OfficeMembership.compositeId(userId, officeIdFromUserDoc);
    return _db.collection(_col).doc(docId).snapshots().map((s) {
      if (!s.exists) return null;
      return OfficeMembership.fromFirestore(s.id, s.data());
    });
  }

  /// Ofisteki tüm üyelikler (yönetici listesi).
  static Stream<List<OfficeMembership>> watchMembershipsForOffice(
      String officeId) {
    return _db
        .collection(_col)
        .where('officeId', isEqualTo: officeId)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => OfficeMembership.fromFirestore(d.id, d.data()))
          .whereType<OfficeMembership>()
          .toList();
    });
  }

  static Future<void> updateMembershipFields(
    String docId,
    Map<String, dynamic> patch,
  ) async {
    await _db.collection(_col).doc(docId).update({
      ...patch,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<OfficeMembership?> getMembershipDoc(String docId) async {
    try {
      final s = await _db.collection(_col).doc(docId).get();
      if (!s.exists) return null;
      return OfficeMembership.fromFirestore(s.id, s.data());
    } catch (e, st) {
      if (kDebugMode)
        AppLogger.e('OfficeMembershipRepository.getMembershipDoc', e, st);
      rethrow;
    }
  }
}
