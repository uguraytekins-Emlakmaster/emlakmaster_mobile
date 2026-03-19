import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore invites/{id} — email daveti: rol ve ekip atanır, ilk girişte users doc'a uygulanır.
class InviteDoc {
  const InviteDoc({
    required this.id,
    required this.email,
    required this.role,
    required this.createdBy,
    this.teamId,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String role;
  final String createdBy;
  final String? teamId;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static InviteDoc? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final email = data['email'] as String? ?? '';
    if (email.isEmpty) return null;
    return InviteDoc(
      id: id,
      email: email,
      role: data['role'] as String? ?? 'agent',
      createdBy: data['createdBy'] as String? ?? '',
      teamId: data['teamId'] as String?,
      name: data['name'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }
}
