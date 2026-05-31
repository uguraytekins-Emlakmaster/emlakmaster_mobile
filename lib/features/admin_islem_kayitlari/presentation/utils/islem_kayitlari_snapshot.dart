import 'package:emlakmaster_mobile/core/models/invite_doc.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/data/audit_log_entry.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:intl/intl.dart';

final _relativeFormatter = DateFormat('d MMM HH:mm', 'tr_TR');
final _dateOnlyFormatter = DateFormat('d MMM yyyy HH:mm', 'tr_TR');

String formatIslemKayitlariTimestamp(DateTime? at, DateTime now) {
  if (at == null) return 'Zaman bilinmiyor';
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inHours < 24) {
    return '${diff.inHours > 0 ? '${diff.inHours} sa ' : ''}${diff.inMinutes % 60} dk önce';
  }
  if (diff.inDays < 7) return _relativeFormatter.format(at);
  return _dateOnlyFormatter.format(at);
}

IslemKayitlariPageSnapshot computeIslemKayitlariSnapshot({
  required List<AuditLogEntry> auditLogs,
  required List<InviteDoc> invites,
  required List<UserDoc> consultants,
  required DateTime now,
}) {
  final nameByUid = <String, String>{};
  for (final u in consultants) {
    final label = u.name?.trim();
    if (label != null && label.isNotEmpty) {
      nameByUid[u.uid] = label;
    } else if (u.email != null && u.email!.isNotEmpty) {
      nameByUid[u.uid] = u.email!;
    }
  }

  final rows = <IslemKayitlariRowViewModel>[];

  for (final log in auditLogs) {
    rows.add(_rowFromAuditLog(log, nameByUid, now));
  }
  for (final invite in invites) {
    rows.add(_rowFromInvite(invite, nameByUid, now));
  }

  rows.sort((a, b) {
    final aAt = a.occurredAt;
    final bAt = b.occurredAt;
    if (aAt == null && bAt == null) return 0;
    if (aAt == null) return 1;
    if (bAt == null) return -1;
    return bAt.compareTo(aAt);
  });

  final cutoff24 = now.subtract(const Duration(hours: 24));
  var last24 = 0;
  var critical = 0;
  var team = 0;
  var consultant = 0;
  var inviteCount = 0;
  var warning = 0;

  for (final row in rows) {
    if (row.occurredAt != null && row.occurredAt!.isAfter(cutoff24)) last24++;
    if (row.severity == IslemKayitlariSeverity.critical) critical++;
    if (row.severity == IslemKayitlariSeverity.warning ||
        row.severity == IslemKayitlariSeverity.critical) {
      warning++;
    }
    switch (row.category) {
      case IslemKayitlariCategory.team:
        team++;
      case IslemKayitlariCategory.consultant:
        consultant++;
      case IslemKayitlariCategory.invite:
        inviteCount++;
      default:
        break;
    }
  }

  final hasAudit = auditLogs.isNotEmpty;
  final hasInvites = invites.isNotEmpty;
  const partialLimitHint = 200;
  final partial = !hasAudit || auditLogs.length >= partialLimitHint;

  final coverageNote = _coverageNote(
    hasAuditLogs: hasAudit,
    hasInvites: hasInvites,
    auditCount: auditLogs.length,
    limitHint: partialLimitHint,
  );

  return IslemKayitlariPageSnapshot(
    rows: rows,
    strip: IslemKayitlariHealthStrip(
      last24hCount: last24,
      criticalCount: critical,
      teamChangeCount: team,
      consultantActionCount: consultant,
      inviteCount: inviteCount,
      warningCount: warning,
      totalEvents: rows.length,
      auditLogCount: auditLogs.length,
      hasPartialCoverage: partial,
    ),
    isEmpty: rows.isEmpty,
    hasAuditLogs: hasAudit,
    hasInvites: hasInvites,
    coverageNote: coverageNote,
  );
}

String _coverageNote({
  required bool hasAuditLogs,
  required bool hasInvites,
  required int auditCount,
  required int limitHint,
}) {
  if (!hasAuditLogs && !hasInvites) {
    return 'Henüz kayıtlı operasyon geçmişi yok. Tam denetim kapsamı genişletildikçe admin işlemleri burada görünecek.';
  }
  if (!hasAuditLogs && hasInvites) {
    return 'Kapsam: yalnızca davet kayıtları görüntüleniyor. audit_logs henüz boş veya yazılmıyor.';
  }
  if (hasAuditLogs && auditCount >= limitHint) {
    return 'Son $limitHint audit kaydı gösteriliyor; daha eski kayıtlar listelenmez.';
  }
  return 'Kaynaklar: audit_logs ve davet kayıtları. Tüm admin işlemleri henüz loglanmıyor olabilir.';
}

IslemKayitlariRowViewModel _rowFromAuditLog(
  AuditLogEntry log,
  Map<String, String> nameByUid,
  DateTime now,
) {
  final actionLower = log.action.toLowerCase();
  final targetLower = log.targetType.toLowerCase();
  final messageLower = log.message.toLowerCase();
  final haystack = '$actionLower $targetLower $messageLower ${log.details.toLowerCase()}';

  final category = _classifyCategory(haystack, log);
  final severity = _classifySeverity(log.severity, haystack);
  final actorName = log.actorName.isNotEmpty
      ? log.actorName
      : (nameByUid[log.actorId] ?? (log.actorId.isNotEmpty ? log.actorId : 'Bilinmeyen'));
  final title = log.message.isNotEmpty
      ? log.message
      : (log.action.isNotEmpty ? _humanizeAction(log.action) : 'Sistem işlemi');

  final consultantId = log.consultantId.isNotEmpty
      ? log.consultantId
      : (_looksLikeUserTarget(haystack) ? _nonEmpty(log.targetId) : null);
  final teamId = log.teamId.isNotEmpty ? log.teamId : null;

  final targetLine = _buildTargetLine(log, nameByUid, consultantId, teamId);
  final detailLine = log.details.isNotEmpty
      ? log.details
      : (log.action.isNotEmpty && log.message.isNotEmpty ? log.action : '');

  final partial = log.occurredAt == null ||
      (log.actorId.isEmpty && log.actorName.isEmpty) ||
      (log.action.isEmpty && log.message.isEmpty);

  return IslemKayitlariRowViewModel(
    id: 'audit:${log.id}',
    title: title,
    actorLine: actorName,
    targetLine: targetLine,
    detailLine: detailLine,
    timestampLabel: formatIslemKayitlariTimestamp(log.occurredAt, now),
    occurredAt: log.occurredAt,
    severity: severity,
    category: category,
    source: IslemKayitlariEventSource.auditLog,
    sourceLabel: 'Audit kaydı',
    categoryLabel: _categoryLabel(category),
    suggestedFilter: _filterForCategory(category, severity),
    consultantId: consultantId,
    teamId: teamId,
    hasPartialMetadata: partial,
  );
}

IslemKayitlariRowViewModel _rowFromInvite(
  InviteDoc invite,
  Map<String, String> nameByUid,
  DateTime now,
) {
  final creator = nameByUid[invite.createdBy] ??
      (invite.createdBy.isNotEmpty ? invite.createdBy : 'Yönetici');
  final roleLabel = _humanizeRole(invite.role);
  final email = invite.email;
  final namePart = invite.name?.trim();
  final target = namePart != null && namePart.isNotEmpty ? namePart : email;

  final detailParts = <String>[
    'Rol: $roleLabel',
    if (invite.teamId != null && invite.teamId!.isNotEmpty) 'Ekip ataması var',
  ];

  return IslemKayitlariRowViewModel(
    id: 'invite:${invite.id}',
    title: 'Davet oluşturuldu',
    actorLine: creator,
    targetLine: target,
    detailLine: detailParts.join(' · '),
    timestampLabel: formatIslemKayitlariTimestamp(invite.createdAt, now),
    occurredAt: invite.createdAt,
    severity: IslemKayitlariSeverity.info,
    category: IslemKayitlariCategory.invite,
    source: IslemKayitlariEventSource.invite,
    sourceLabel: 'Davet kaydı',
    categoryLabel: 'Invite',
    suggestedFilter: IslemKayitlariFilter.invite,
    consultantId: null,
    teamId: invite.teamId,
    hasPartialMetadata: invite.createdAt == null,
  );
}

IslemKayitlariCategory _classifyCategory(String haystack, AuditLogEntry log) {
  if (_containsAny(haystack, ['invite', 'davet', 'membership'])) {
    return IslemKayitlariCategory.invite;
  }
  if (_containsAny(haystack, ['role', 'yetki', 'permission', 'rol'])) {
    return IslemKayitlariCategory.role;
  }
  if (_containsAny(haystack, ['assign', 'atama', 'transfer', 'manager'])) {
    return IslemKayitlariCategory.assignment;
  }
  if (_containsAny(haystack, ['team', 'ekip', 'group'])) {
    return IslemKayitlariCategory.team;
  }
  if (_containsAny(haystack, [
        'consultant',
        'danışman',
        'danisman',
        'agent',
        'advisor',
        'user',
        'member',
      ]) ||
      log.consultantId.isNotEmpty) {
    return IslemKayitlariCategory.consultant;
  }
  if (_containsAny(haystack, ['warn', 'error', 'fail', 'uyarı', 'hata'])) {
    return IslemKayitlariCategory.warning;
  }
  return IslemKayitlariCategory.general;
}

IslemKayitlariSeverity _classifySeverity(String severityRaw, String haystack) {
  final s = severityRaw.toLowerCase();
  if (s.contains('critical') ||
      s.contains('kritik') ||
      _containsAny(haystack, ['delete', 'sil', 'revoke', 'remove_role'])) {
    return IslemKayitlariSeverity.critical;
  }
  if (s.contains('warn') ||
      s.contains('error') ||
      s.contains('fail') ||
      _containsAny(haystack, ['warn', 'error', 'fail', 'uyarı', 'hata'])) {
    return IslemKayitlariSeverity.warning;
  }
  return IslemKayitlariSeverity.info;
}

IslemKayitlariFilter _filterForCategory(
  IslemKayitlariCategory category,
  IslemKayitlariSeverity severity,
) {
  if (severity == IslemKayitlariSeverity.critical) {
    return IslemKayitlariFilter.critical;
  }
  return switch (category) {
    IslemKayitlariCategory.consultant => IslemKayitlariFilter.consultant,
    IslemKayitlariCategory.team => IslemKayitlariFilter.team,
    IslemKayitlariCategory.invite => IslemKayitlariFilter.invite,
    IslemKayitlariCategory.role => IslemKayitlariFilter.role,
    IslemKayitlariCategory.assignment => IslemKayitlariFilter.assignment,
    IslemKayitlariCategory.warning => IslemKayitlariFilter.warning,
    IslemKayitlariCategory.general => IslemKayitlariFilter.all,
  };
}

String _buildTargetLine(
  AuditLogEntry log,
  Map<String, String> nameByUid,
  String? consultantId,
  String? teamId,
) {
  if (log.targetType.isNotEmpty && log.targetId.isNotEmpty) {
    final name = nameByUid[log.targetId];
    if (name != null) return '${log.targetType} · $name';
    return '${log.targetType} · ${log.targetId}';
  }
  if (consultantId != null) {
    return nameByUid[consultantId] ?? consultantId;
  }
  if (teamId != null) return 'Ekip · $teamId';
  return '';
}

String _humanizeAction(String action) {
  return action
      .replaceAll('_', ' ')
      .replaceAll('.', ' ')
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => p.length > 1 ? '${p[0].toUpperCase()}${p.substring(1)}' : p.toUpperCase())
      .join(' ');
}

String _humanizeRole(String role) {
  return switch (role) {
    'agent' => 'Danışman',
    'team_lead' => 'Ekip lideri',
    'office_manager' => 'Ofis yöneticisi',
    'general_manager' => 'Genel müdür',
    'broker_owner' => 'Broker',
    _ => role,
  };
}

String _categoryLabel(IslemKayitlariCategory category) {
  return switch (category) {
    IslemKayitlariCategory.consultant => 'Danışman',
    IslemKayitlariCategory.team => 'Ekip',
    IslemKayitlariCategory.invite => 'Invite',
    IslemKayitlariCategory.role => 'Yetki',
    IslemKayitlariCategory.assignment => 'Atama',
    IslemKayitlariCategory.warning => 'Uyarı',
    IslemKayitlariCategory.general => 'Genel',
  };
}

bool _containsAny(String haystack, List<String> needles) {
  for (final n in needles) {
    if (haystack.contains(n)) return true;
  }
  return false;
}

bool _looksLikeUserTarget(String haystack) {
  return _containsAny(haystack, ['user', 'consultant', 'agent', 'danışman', 'danisman']);
}

String? _nonEmpty(String v) => v.isNotEmpty ? v : null;
