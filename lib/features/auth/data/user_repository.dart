import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';

/// Firestore users/{uid} yapısı. role: super_admin | broker | office_manager | team_lead | agent | operations | investor
class UserDoc {
  const UserDoc({
    required this.uid,
    required this.role,
    this.name,
    this.email,
    this.avatarUrl,
    this.isActive = true,
    /// Birincil ofis (çok kiracılı üyelik). Üyelik detayı `office_memberships`.
    this.officeId,
    this.teamId,
    this.managerId,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String role;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final bool isActive;
  final String? officeId;
   /// Ekip kimliği (her danışman tek ekipte).
  final String? teamId;

  /// Bu kullanıcının bağlı olduğu yönetici / ekip lideri.
  final String? managerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static UserDoc? fromFirestore(String uid, Map<String, dynamic>? data) {
    if (data == null) return null;
    final role = data['role'] as String?;
    if (role == null || role.isEmpty) return null;
    return UserDoc(
      uid: uid,
      role: role,
      name: data['name'] as String?,
      email: data['email'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      officeId: data['officeId'] as String?,
      teamId: data['teamId'] as String?,
      managerId: data['managerId'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}

/// users koleksiyonu okuma/yazma. İlk admin: doc yoksa superAdmin oluşturur.
class UserRepository {
  UserRepository._();

  static FirebaseFirestore get _store => FirebaseFirestore.instance;

  static String get _usersCol => AppConstants.colUsers;

  /// users/{uid} dokümanını getirir. Yoksa null.
  static Future<UserDoc?> getUserDoc(String uid) async {
    try {
      final ref = _store.collection(_usersCol).doc(uid);
      final snap = await ref.get();
      if (!snap.exists || snap.data() == null) return null;
      return UserDoc.fromFirestore(uid, snap.data());
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('UserRepository.getUserDoc', e, st);
      rethrow;
    }
  }

  /// users/{uid} stream (rol değişikliklerini dinlemek için).
  /// İlk abonelikte geçici ağ/kural gecikmesi olabilir; bir kez yeniden dener.
  static Stream<UserDoc?> userDocStream(String uid) {
    return _store.collection(_usersCol).doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserDoc.fromFirestore(uid, snap.data());
    }).handleError((Object e, StackTrace st) {
      if (kDebugMode) AppLogger.e('UserRepository.userDocStream($uid)', e, st);
      Error.throwWithStackTrace(e, st);
    });
  }

  /// Yeni kullanıcı dokümanı oluşturur veya günceller. İlk girişte role=superAdmin kullanılabilir.
  static Future<void> setUserDoc({
    required String uid,
    required String role,
    String? name,
    String? email,
    bool isActive = true,
    String? officeId,
    String? teamId,
    String? managerId,
  }) async {
    try {
      final ref = _store.collection(_usersCol).doc(uid);
      final existing = (await ref.get()).data();
      await ref.set({
        'uid': uid,
        'role': role,
        'name': name,
        'email': email,
        'isActive': isActive,
        if (officeId != null) 'officeId': officeId,
        if (teamId != null) 'teamId': teamId,
        if (managerId != null) 'managerId': managerId,
        'updatedAt': FieldValue.serverTimestamp(),
        if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kDebugMode) AppLogger.d('UserRepository.setUserDoc: $uid role=$role');
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('UserRepository.setUserDoc', e, st);
      rethrow;
    }
  }

  /// `users/{uid}` **varsa** ad/e-posta günceller; yoksa no-op (rol oluşturma burada yapılmaz).
  static Future<void> mergeProfileIfDocExists({
    required String uid,
    String? name,
    String? email,
  }) async {
    try {
      final ref = _store.collection(_usersCol).doc(uid);
      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final patch = <String, dynamic>{};
      final n = name?.trim();
      if (n != null && n.isNotEmpty) {
        final cur = data['name'] as String?;
        if (cur == null || cur.isEmpty) {
          patch['name'] = n;
        }
      }
      final em = email?.trim();
      if (em != null && em.isNotEmpty) {
        final cur = data['email'] as String?;
        if (cur == null || cur.isEmpty) {
          patch['email'] = em;
        }
      }
      if (patch.isEmpty) return;
      patch['updatedAt'] = FieldValue.serverTimestamp();
      await ref.set(patch, SetOptions(merge: true));
      if (kDebugMode) AppLogger.d('UserRepository.mergeProfileIfDocExists: $uid');
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('UserRepository.mergeProfileIfDocExists', e, st);
      rethrow;
    }
  }

  /// Sadece ekip alanlarını günceller (assign/remove agent from team). Null = alanı kaldır.
  static Future<void> updateUserTeamFields(
    String uid,
    String? teamId,
    String? managerId,
  ) async {
    try {
      final ref = _store.collection(_usersCol).doc(uid);
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (teamId == null) {
        updates['teamId'] = FieldValue.delete();
      } else {
        updates['teamId'] = teamId;
      }
      if (managerId == null) {
        updates['managerId'] = FieldValue.delete();
      } else {
        updates['managerId'] = managerId;
      }
      await ref.update(updates);
      if (kDebugMode) AppLogger.d('UserRepository.updateUserTeamFields: $uid teamId=$teamId');
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('UserRepository.updateUserTeamFields', e, st);
      rethrow;
    }
  }

  /// Koleksiyonda hiç kullanıcı var mı? (İlk admin tespiti için.)
  static Future<bool> hasAnyUser() async {
    try {
      final snap = await _store.collection(_usersCol).limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('UserRepository.hasAnyUser', e, st);
      return false;
    }
  }
}
