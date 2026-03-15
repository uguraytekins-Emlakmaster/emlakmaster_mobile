import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

/// Kritik yetki değişiklikleri ve admin aksiyonları için audit log.
/// Firestore audit_logs koleksiyonu (kurallarda sadece backend yazabilir olabilir; istemci yazıyorsa rule güncelle).
class AuditLogService {
  AuditLogService._();

  static Future<void> logAdminAction({
    required String action,
    String? targetUserId,
    String? targetRole,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection(AppConstants.colAuditLogs).add({
        'type': 'admin_action',
        'action': action,
        'actorUid': user.uid,
        'actorEmail': user.email,
        'targetUserId': targetUserId,
        'targetRole': targetRole,
        if (extra != null) ...extra,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) AppLogger.d('AuditLog: $action');
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('AuditLog failed', e, st);
    }
  }
}
