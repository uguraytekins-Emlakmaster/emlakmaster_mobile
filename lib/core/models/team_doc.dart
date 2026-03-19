import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore teams/{teamId} dokümanı. Flat ekip: name, managerId, memberIds.
class TeamDoc {
  const TeamDoc({
    required this.id,
    required this.name,
    required this.managerId,
    this.memberIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String managerId;
  final List<String> memberIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static TeamDoc? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['name'] as String? ?? '';
    final managerId = data['managerId'] as String? ?? '';
    final memberIds = data['memberIds'] as List<dynamic>?;
    return TeamDoc(
      id: id,
      name: name,
      managerId: managerId,
      memberIds: memberIds != null
          ? memberIds.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
          : const [],
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }
}
