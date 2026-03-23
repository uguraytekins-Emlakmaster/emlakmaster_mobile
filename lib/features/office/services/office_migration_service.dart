import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../auth/data/user_repository.dart';
import '../domain/office_exception.dart';
import '../domain/office_membership_entity.dart';
import '../data/office_membership_repository.dart';

/// Legacy kullanıcılar: işaretçi / üyelik onarımı (kurallar izin verdiği ölçüde).
abstract final class OfficeMigrationService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// `officeId` var ama birincil üyelik dokümanı yok: işaretçiyi temizle (yeniden katılım).
  /// [OfficeIntegrityService.isCorruptedState] true iken anlamlıdır.
  static Future<void> clearOfficePointerIfMembershipMissing({
    required String uid,
    required String officeId,
  }) async {
    final mid = OfficeMembership.compositeId(uid, officeId);
    final mem = await OfficeMembershipRepository.getMembershipDoc(mid);
    if (mem != null) {
      throw OfficeException(
        OfficeErrorCode.officeStateCorrupted,
        'Üyelik kaydı bulundu; otomatik sıfırlama yapılmadı.',
      );
    }
    try {
      await _db.collection(AppConstants.colUsers).doc(uid).set(
        {
          'officeId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('OfficeMigrationService.clearOfficePointerIfMembershipMissing', e, st);
      throw OfficeException(
        OfficeErrorCode.permissionDenied,
        'Ofis bağlantısı temizlenemedi. Yöneticinizle iletişime geçin.',
        e,
      );
    }
  }

  /// Kullanıcı doc’u yoksa veya ofis bağlamı yoksa — bilgi amaçlı.
  static Future<bool> userNeedsOfficeBootstrap(String uid) async {
    final doc = await UserRepository.getUserDoc(uid);
    if (doc == null) return true;
    final oid = doc.officeId;
    return oid == null || oid.isEmpty;
  }
}
