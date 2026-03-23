import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/membership_status.dart';
import '../domain/office_exception.dart';
import '../domain/office_membership_entity.dart';
import '../domain/office_role.dart';
import '../data/office_invite_repository.dart';
import '../data/office_membership_repository.dart';
/// Ofis yönetimi: üye durumu, davet, temel ayarlar (kurallarla korunmalı).
abstract final class OfficeAdminService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<OfficeMembership?> _requireActiveManagerOrAbove({
    required String uid,
    required String officeId,
  }) async {
    final mid = OfficeMembership.compositeId(uid, officeId);
    final mem = await OfficeMembershipRepository.getMembershipDoc(mid);
    if (mem == null || mem.status != MembershipStatus.active) {
      throw OfficeException(
        OfficeErrorCode.permissionDenied,
        'Bu ofiste yönetim yetkiniz yok.',
      );
    }
    if (mem.role != OfficeRole.owner &&
        mem.role != OfficeRole.admin &&
        mem.role != OfficeRole.manager) {
      throw OfficeException(
        OfficeErrorCode.permissionDenied,
        'Bu işlem için yönetici veya üst rol gerekir.',
      );
    }
    return mem;
  }

  /// Üye askıya alma (owner/admin/manager).
  static Future<void> suspendMember({
    required User user,
    required String officeId,
    required String targetUserId,
  }) async {
    if (targetUserId == user.uid) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Kendi hesabınızı askıya alamazsınız.');
    }
    await _requireActiveManagerOrAbove(uid: user.uid, officeId: officeId);
    final tid = OfficeMembership.compositeId(targetUserId, officeId);
    final tmem = await OfficeMembershipRepository.getMembershipDoc(tid);
    if (tmem == null || tmem.officeId != officeId) {
      throw OfficeException(OfficeErrorCode.officeNotFound, 'Üye bulunamadı.');
    }
    if (tmem.role == OfficeRole.owner) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Ofis sahibi askıya alınamaz.');
    }
    await OfficeMembershipRepository.updateMembershipFields(tid, {
      'status': MembershipStatus.suspended.name,
    });
  }

  /// Üyelik kaldırıldı olarak işaretle (owner/admin/manager).
  static Future<void> removeMember({
    required User user,
    required String officeId,
    required String targetUserId,
  }) async {
    if (targetUserId == user.uid) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Kendi üyeliğinizi buradan kaldıramazsınız.');
    }
    final actor = await _requireActiveManagerOrAbove(uid: user.uid, officeId: officeId);
    final tid = OfficeMembership.compositeId(targetUserId, officeId);
    final tmem = await OfficeMembershipRepository.getMembershipDoc(tid);
    if (tmem == null || tmem.officeId != officeId) {
      throw OfficeException(OfficeErrorCode.officeNotFound, 'Üye bulunamadı.');
    }
    if (tmem.role == OfficeRole.owner) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Ofis sahibi kaldırılamaz.');
    }
    if (actor!.role == OfficeRole.manager && tmem.role != OfficeRole.consultant) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Bu rolü kaldırma yetkiniz yok.');
    }
    await OfficeMembershipRepository.updateMembershipFields(tid, {
      'status': MembershipStatus.removed.name,
    });
    // Hedef kullanıcının users.officeId eşlemesi — yönetici veya backend ile senkron önerilir.
    try {
      await _db.collection(AppConstants.colUsers).doc(targetUserId).set(
        {
          'officeId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('OfficeAdminService.removeMember users patch', e, st);
      // Üyelik removed kaldı; kullanıcı doc güncellenemezse kurallar yüzünden — yine de hata göster.
      throw OfficeException(
        OfficeErrorCode.permissionDenied,
        'Üyelik güncellendi; kullanıcı kaydı tamamlanamadı. Yönetici ile iletişime geçin.',
        e,
      );
    }
  }

  /// Daveti pasifleştir.
  static Future<void> deactivateInvite({
    required User user,
    required String officeId,
    required String inviteId,
  }) async {
    await _requireActiveManagerOrAbove(uid: user.uid, officeId: officeId);
    await OfficeInviteRepository.deactivateInvite(
      inviteId: inviteId,
      expectedOfficeId: officeId,
    );
  }

  /// Ofis adı (owner/admin).
  static Future<void> updateOfficeName({
    required User user,
    required String officeId,
    required String newName,
  }) async {
    final mem = await _requireActiveManagerOrAbove(uid: user.uid, officeId: officeId);
    if (mem!.role == OfficeRole.manager) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Ofis adını yalnızca sahip veya yönetici değiştirebilir.');
    }
    final n = newName.trim();
    if (n.isEmpty) {
      throw OfficeException(OfficeErrorCode.unknown, 'Ofis adı boş olamaz.');
    }
    await _db.collection(AppConstants.colOffices).doc(officeId).set(
      {
        'name': n,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
