import 'package:cloud_firestore/cloud_firestore.dart';

import 'office_role.dart';

/// Firestore `office_invites/{id}` — kısa kod ile ofise katılım.
class OfficeInvite {
  const OfficeInvite({
    required this.id,
    required this.officeId,
    required this.code,
    required this.createdBy,
    this.expiresAt,
    required this.maxUses,
    required this.usedCount,
    required this.roleToAssign,
    this.isActive = true,
  });

  final String id;
  final String officeId;
  /// Büyük harf, kısa (örn. 8 karakter).
  final String code;
  final String createdBy;
  final DateTime? expiresAt;
  final int maxUses;
  final int usedCount;
  final OfficeRole roleToAssign;
  final bool isActive;

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isExhausted => usedCount >= maxUses;

  Map<String, dynamic> toFirestoreCreate() {
    final m = <String, dynamic>{
      'officeId': officeId,
      'code': code,
      'createdBy': createdBy,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'roleToAssign': roleToAssign.name,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (expiresAt != null) {
      m['expiresAt'] = Timestamp.fromDate(expiresAt!);
    }
    return m;
  }

  static OfficeInvite? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final role = parseOfficeRole(data['roleToAssign'] as String?);
    if (role == null) return null;
    return OfficeInvite(
      id: id,
      officeId: data['officeId'] as String? ?? '',
      code: (data['code'] as String? ?? '').toUpperCase(),
      createdBy: data['createdBy'] as String? ?? '',
      expiresAt: _ts(data['expiresAt']),
      maxUses: (data['maxUses'] as num?)?.toInt() ?? 1,
      usedCount: (data['usedCount'] as num?)?.toInt() ?? 0,
      roleToAssign: role,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
