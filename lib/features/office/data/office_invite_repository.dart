import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/office_exception.dart';
import '../domain/office_invite_entity.dart';

/// Kısa kod üretimi ve benzersizlik (istemci tarafı; kurallar sunucuda doğrulanmalı).
abstract final class OfficeInviteCodeGenerator {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate({int length = 8}) {
    final r = Random.secure();
    return List.generate(length, (_) => _alphabet[r.nextInt(_alphabet.length)]).join();
  }
}

class OfficeInviteRepository {
  OfficeInviteRepository._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String get _col => AppConstants.colOfficeInvites;

  /// [code] büyük harf normalize.
  static Future<OfficeInvite?> findActiveInviteByCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length < 4) return null;
    try {
      final q = await _db
          .collection(_col)
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return null;
      final d = q.docs.first;
      return OfficeInvite.fromFirestore(d.id, d.data());
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('OfficeInviteRepository.findActiveInviteByCode', e, st);
      rethrow;
    }
  }

  /// Yeni davet — benzersiz kod için birkaç deneme.
  static Future<({String id, String code})> createInviteDocument({
    required String officeId,
    required String createdBy,
    required OfficeInvite draft,
  }) async {
    String code = draft.code;
    for (var i = 0; i < 8; i++) {
      final exists = await _db
          .collection(_col)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (exists.docs.isEmpty) break;
      code = OfficeInviteCodeGenerator.generate();
    }
    final ref = _db.collection(_col).doc();
    final data = Map<String, dynamic>.from(draft.toFirestoreCreate());
    data['code'] = code;
    data['officeId'] = officeId;
    data['createdBy'] = createdBy;
    await ref.set(data);
    return (id: ref.id, code: code);
  }

  /// Ofise ait davetler (yönetici listesi).
  static Stream<List<OfficeInvite>> watchInvitesForOffice(String officeId) {
    return _db
        .collection(_col)
        .where('officeId', isEqualTo: officeId)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => OfficeInvite.fromFirestore(d.id, d.data()))
          .whereType<OfficeInvite>()
          .toList();
    });
  }

  static Future<void> deactivateInvite({
    required String inviteId,
    required String expectedOfficeId,
  }) async {
    final ref = _db.collection(_col).doc(inviteId);
    await _db.runTransaction((tx) async {
      final s = await tx.get(ref);
      if (!s.exists) {
        throw OfficeException(OfficeErrorCode.invalidInviteCode, 'Davet bulunamadı.');
      }
      final inv = OfficeInvite.fromFirestore(s.id, s.data());
      if (inv == null || inv.officeId != expectedOfficeId) {
        throw OfficeException(OfficeErrorCode.permissionDenied, 'Davet bu ofise ait değil.');
      }
      tx.update(ref, {
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
