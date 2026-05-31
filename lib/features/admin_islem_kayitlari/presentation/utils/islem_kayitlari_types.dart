/// İşlem kayıtları filtreleri — yalnızca gerçek metadata sınıflandırması.
enum IslemKayitlariFilter {
  all,
  consultant,
  team,
  invite,
  role,
  assignment,
  warning,
  last24h,
  critical,
}

enum IslemKayitlariCategory {
  consultant,
  team,
  invite,
  role,
  assignment,
  warning,
  general,
}

enum IslemKayitlariEventSource {
  auditLog,
  invite,
}

enum IslemKayitlariSeverity {
  info,
  warning,
  critical,
}

class IslemKayitlariHealthStrip {
  const IslemKayitlariHealthStrip({
    required this.last24hCount,
    required this.criticalCount,
    required this.teamChangeCount,
    required this.consultantActionCount,
    required this.inviteCount,
    required this.warningCount,
    required this.totalEvents,
    required this.auditLogCount,
    required this.hasPartialCoverage,
  });

  final int last24hCount;
  final int criticalCount;
  final int teamChangeCount;
  final int consultantActionCount;
  final int inviteCount;
  final int warningCount;
  final int totalEvents;
  final int auditLogCount;
  final bool hasPartialCoverage;

  static const empty = IslemKayitlariHealthStrip(
    last24hCount: 0,
    criticalCount: 0,
    teamChangeCount: 0,
    consultantActionCount: 0,
    inviteCount: 0,
    warningCount: 0,
    totalEvents: 0,
    auditLogCount: 0,
    hasPartialCoverage: true,
  );
}

class IslemKayitlariRowViewModel {
  const IslemKayitlariRowViewModel({
    required this.id,
    required this.title,
    required this.actorLine,
    required this.targetLine,
    required this.detailLine,
    required this.timestampLabel,
    required this.occurredAt,
    required this.severity,
    required this.category,
    required this.source,
    required this.sourceLabel,
    required this.categoryLabel,
    required this.suggestedFilter,
    required this.consultantId,
    required this.teamId,
    required this.hasPartialMetadata,
  });

  final String id;
  final String title;
  final String actorLine;
  final String targetLine;
  final String detailLine;
  final String timestampLabel;
  final DateTime? occurredAt;
  final IslemKayitlariSeverity severity;
  final IslemKayitlariCategory category;
  final IslemKayitlariEventSource source;
  final String sourceLabel;
  final String categoryLabel;
  final IslemKayitlariFilter suggestedFilter;
  final String? consultantId;
  final String? teamId;
  final bool hasPartialMetadata;
}

class IslemKayitlariPageSnapshot {
  const IslemKayitlariPageSnapshot({
    required this.rows,
    required this.strip,
    required this.isEmpty,
    required this.hasAuditLogs,
    required this.hasInvites,
    required this.coverageNote,
  });

  final List<IslemKayitlariRowViewModel> rows;
  final IslemKayitlariHealthStrip strip;
  final bool isEmpty;
  final bool hasAuditLogs;
  final bool hasInvites;
  final String coverageNote;
}
