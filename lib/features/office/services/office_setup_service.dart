import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/entities/app_role.dart';
import '../domain/membership_status.dart' show MembershipStatus, parseMembershipStatus;
import '../domain/office_entity.dart';
import '../domain/office_exception.dart';
import '../domain/office_invite_entity.dart';
import '../domain/office_membership_entity.dart';
import '../domain/office_role.dart';
import '../data/office_invite_repository.dart';
import '../data/office_membership_repository.dart';

/// Ofis oluşturma ve davet ile katılma — batch / transaction.
class OfficeSetupService {
  OfficeSetupService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Ofis + owner üyeliği + kullanıcı `officeId` / rol senkronu (atomic batch).
  static Future<String> createOfficeAsOwner({
    required User user,
    required String officeName,
  }) async {
    final uid = user.uid;
    final existing = await UserRepository.getUserDoc(uid);
    if (existing?.officeId != null && existing!.officeId!.isNotEmpty) {
      return existing.officeId!;
    }

    final name = officeName.trim();
    if (name.isEmpty) {
      throw OfficeException(OfficeErrorCode.unknown, 'Ofis adı gerekli.');
    }

    final officeRef = _db.collection(AppConstants.colOffices).doc();
    final officeId = officeRef.id;
    final membershipId = OfficeMembership.compositeId(uid, officeId);

    final office = Office(
      id: officeId,
      name: name,
      createdBy: uid,
    );

    final membership = OfficeMembership(
      id: membershipId,
      officeId: officeId,
      userId: uid,
      role: OfficeRole.owner,
      status: MembershipStatus.active,
    );

    final batch = _db.batch();
    batch.set(officeRef, office.toFirestoreCreate());
    batch.set(
      _db.collection(AppConstants.colOfficeMemberships).doc(membershipId),
      membership.toFirestoreCreate(),
    );
    batch.set(
      _db.collection(AppConstants.colUsers).doc(uid),
      {
        'officeId': officeId,
        'role': AppRole.brokerOwner.id,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('OfficeSetupService.createOfficeAsOwner', e, st);
      throw OfficeException(OfficeErrorCode.network, 'Ofis oluşturulamadı. Bağlantınızı kontrol edin.', e);
    }
    return officeId;
  }

  /// Davet kodu ile katıl — transaction.
  static Future<void> joinOfficeWithInviteCode({
    required User user,
    required String rawCode,
  }) async {
    final uid = user.uid;
    final code = rawCode.trim().toUpperCase();
    if (code.length < 4) {
      throw OfficeException(OfficeErrorCode.invalidInviteCode, 'Geçersiz davet kodu.');
    }

    final userDoc = await UserRepository.getUserDoc(uid);
    if (userDoc?.officeId != null && userDoc!.officeId!.isNotEmpty) {
      throw OfficeException(OfficeErrorCode.alreadyMember, 'Zaten bir ofise bağlısınız.');
    }

    final prelim = await OfficeInviteRepository.findActiveInviteByCode(code);
    if (prelim == null) {
      throw OfficeException(OfficeErrorCode.invalidInviteCode, 'Davet kodu bulunamadı veya geçersiz.');
    }

    await _db.runTransaction((tx) async {
      final inviteRef = _db.collection(AppConstants.colOfficeInvites).doc(prelim.id);
      final inviteSnap = await tx.get(inviteRef);
      if (!inviteSnap.exists) {
        throw OfficeException(OfficeErrorCode.invalidInviteCode, 'Davet bulunamadı.');
      }
      final invite = OfficeInvite.fromFirestore(inviteSnap.id, inviteSnap.data());
      if (invite == null) {
        throw OfficeException(OfficeErrorCode.invalidInviteCode, 'Davet verisi okunamadı.');
      }

      if (!invite.isActive) {
        throw OfficeException(OfficeErrorCode.inviteInactive, 'Bu davet artık geçerli değil.');
      }
      if (invite.isExpired) {
        throw OfficeException(OfficeErrorCode.inviteExpired, 'Davet süresi dolmuş.');
      }
      if (invite.isExhausted) {
        throw OfficeException(OfficeErrorCode.inviteExhausted, 'Davet kullanım limiti dolmuş.');
      }
      if (invite.roleToAssign == OfficeRole.owner) {
        throw OfficeException(OfficeErrorCode.permissionDenied, 'Geçersiz davet yapılandırması.');
      }

      final officeId = invite.officeId;
      final membershipId = OfficeMembership.compositeId(uid, officeId);

      final existingMem = await tx.get(
        _db.collection(AppConstants.colOfficeMemberships).doc(membershipId),
      );
      if (existingMem.exists) {
        final data = existingMem.data();
        final st = parseMembershipStatus(data?['status'] as String?);
        if (st == MembershipStatus.active) {
          throw OfficeException(OfficeErrorCode.alreadyMember, 'Bu ofisin zaten üyesisiniz.');
        }
        if (st == MembershipStatus.suspended) {
          throw OfficeException(
            OfficeErrorCode.membershipSuspended,
            'Hesabınız bu ofiste askıya alınmış. Yöneticinizle iletişime geçin.',
          );
        }
      }

      tx.update(inviteRef, {
        'usedCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final newMembership = OfficeMembership(
        id: membershipId,
        officeId: officeId,
        userId: uid,
        role: invite.roleToAssign,
        status: MembershipStatus.active,
      );
      // Davetle yeniden katılım: removed / invited önceki kayıtlar üzerine yazılır.
      tx.set(
        _db.collection(AppConstants.colOfficeMemberships).doc(membershipId),
        newMembership.toFirestoreCreate(),
      );

      final appRole = invite.roleToAssign.toAppRole();
      tx.set(
        _db.collection(AppConstants.colUsers).doc(uid),
        {
          'officeId': officeId,
          'role': appRole.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Owner / admin tarafından davet oluşturma (üye rolü istemci tarafında doğrulanır).
  static Future<({String id, String code})> createInviteForOffice({
    required User user,
    required String officeId,
    required OfficeRole roleToAssign,
    int maxUses = 5,
    DateTime? expiresAt,
  }) async {
    if (roleToAssign == OfficeRole.owner) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Sahiplik davetle devredilemez.');
    }

    final uid = user.uid;
    final membershipId = OfficeMembership.compositeId(uid, officeId);
    final mem = await OfficeMembershipRepository.getMembershipDoc(membershipId);
    if (mem == null || mem.status != MembershipStatus.active) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Bu ofiste davet oluşturma yetkiniz yok.');
    }
    if (mem.officeId != officeId) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Ofis eşleşmesi hatalı.');
    }
    final canInvite = mem.role == OfficeRole.owner ||
        mem.role == OfficeRole.admin ||
        mem.role == OfficeRole.manager;
    if (!canInvite) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Davet oluşturma yetkiniz yok.');
    }
    if (mem.role == OfficeRole.manager && roleToAssign == OfficeRole.admin) {
      throw OfficeException(OfficeErrorCode.permissionDenied, 'Bu rolü atayamazsınız.');
    }

    final code = OfficeInviteCodeGenerator.generate();
    final draft = OfficeInvite(
      id: '',
      officeId: officeId,
      code: code,
      createdBy: uid,
      expiresAt: expiresAt,
      maxUses: maxUses,
      usedCount: 0,
      roleToAssign: roleToAssign,
    );

    final result = await OfficeInviteRepository.createInviteDocument(
      officeId: officeId,
      createdBy: uid,
      draft: draft,
    );
    return result;
  }
}
