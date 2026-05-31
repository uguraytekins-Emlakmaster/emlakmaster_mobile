import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `audit_logs/{id}` — esnek şema; yalnızca mevcut alanlar okunur.
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.raw,
    this.action = '',
    this.actorId = '',
    this.actorName = '',
    this.targetId = '',
    this.targetType = '',
    this.teamId = '',
    this.consultantId = '',
    this.severity = '',
    this.message = '',
    this.details = '',
    this.occurredAt,
  });

  final String id;
  final Map<String, dynamic> raw;
  final String action;
  final String actorId;
  final String actorName;
  final String targetId;
  final String targetType;
  final String teamId;
  final String consultantId;
  final String severity;
  final String message;
  final String details;
  final DateTime? occurredAt;

  static DateTime? _parseTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static String _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  static AuditLogEntry? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return null;

    final action = _firstString(data, [
      'action',
      'type',
      'eventType',
      'event',
      'operation',
    ]);
    final actorId = _firstString(data, [
      'actorId',
      'actorUid',
      'adminUid',
      'userId',
      'uid',
      'createdBy',
    ]);
    final actorName = _firstString(data, [
      'actorName',
      'userName',
      'adminName',
      'displayName',
    ]);
    final targetId = _firstString(data, [
      'targetId',
      'resourceId',
      'entityId',
      'objectId',
    ]);
    final targetType = _firstString(data, [
      'targetType',
      'resourceType',
      'entityType',
      'objectType',
    ]);
    final teamId = _firstString(data, ['teamId', 'team']);
    final consultantId = _firstString(data, [
      'consultantId',
      'agentId',
      'advisorId',
      'memberId',
    ]);
    final severity = _firstString(data, [
      'severity',
      'level',
      'priority',
    ]).toLowerCase();
    final message = _firstString(data, [
      'message',
      'summary',
      'title',
      'description',
      'detail',
    ]);
    final details = _firstString(data, ['details', 'payload', 'meta']);

    final occurredAt = _parseTimestamp(data['createdAt']) ??
        _parseTimestamp(data['timestamp']) ??
        _parseTimestamp(data['at']) ??
        _parseTimestamp(data['occurredAt']);

    if (action.isEmpty &&
        message.isEmpty &&
        actorId.isEmpty &&
        targetId.isEmpty &&
        occurredAt == null) {
      return null;
    }

    return AuditLogEntry(
      id: id,
      raw: Map<String, dynamic>.unmodifiable(data),
      action: action,
      actorId: actorId,
      actorName: actorName,
      targetId: targetId,
      targetType: targetType,
      teamId: teamId,
      consultantId: consultantId,
      severity: severity,
      message: message,
      details: details,
      occurredAt: occurredAt,
    );
  }
}
