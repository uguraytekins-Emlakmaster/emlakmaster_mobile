import 'package:cloud_firestore/cloud_firestore.dart';

import 'membership_status.dart';
import 'office_role.dart';

/// Firestore `office_memberships/{id}`.
class OfficeMembership {
  const OfficeMembership({
    required this.id,
    required this.officeId,
    required this.userId,
    required this.role,
    this.permissions,
    this.joinedAt,
    required this.status,
  });

  final String id;
  final String officeId;
  final String userId;
  final OfficeRole role;
  final Map<String, dynamic>? permissions;
  final DateTime? joinedAt;
  final MembershipStatus status;

  static String compositeId(String userId, String officeId) => '${userId}_$officeId';

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'officeId': officeId,
      'userId': userId,
      'role': role.name,
      if (permissions != null) 'permissions': permissions,
      'status': status.name,
      'joinedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static OfficeMembership? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final role = parseOfficeRole(data['role'] as String?);
    final st = parseMembershipStatus(data['status'] as String?);
    if (role == null || st == null) return null;
    return OfficeMembership(
      id: id,
      officeId: data['officeId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      role: role,
      permissions: data['permissions'] != null
          ? Map<String, dynamic>.from(data['permissions'] as Map)
          : null,
      joinedAt: _ts(data['joinedAt']),
      status: st,
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
