// Üyelikler / Davetler — yalnızca gerçek office_invites + office_memberships
// metadata'sından türetilen tipler. Uydurma onboarding/lifecycle yok.

/// Yatay filtre seçenekleri (yalnızca grounded kategoriler).
enum UyeliklerFilter {
  all,
  pending,
  accepted,
  expired,
  intervention,
  members,
  invite,
  last7d,
}

/// Satır türü: davet kaydı mı, üyelik kaydı mı.
enum UyelikKind { invite, member }

/// Türetilmiş gösterim durumu (gerçek alanlardan hesaplanır).
enum UyelikDurum {
  // Davet durumları
  pending, // bekliyor (aktif, kullanılmamış, geçerli)
  partiallyUsed, // kısmi kullanıldı (usedCount>0, hâlâ kullanılabilir)
  accepted, // kabul edildi / kontenjan doldu
  expired, // süresi doldu
  closed, // pasifleştirildi
  // Üyelik durumları
  active, // aktif üye
  suspended, // askıda
  removed, // kaldırıldı
  invited, // davetli (membership state — backend'de yazılmıyor, parse güvenliği)
}

/// Renk tonu — widget katmanında tema rengine eşlenir.
enum UyelikTone { info, success, warning, danger, neutral }

class UyeliklerSummaryStrip {
  const UyeliklerSummaryStrip({
    required this.pendingInvites,
    required this.acceptedInvites,
    required this.expiredInvites,
    required this.activeMembers,
    required this.interventionCount,
    required this.totalMembers,
    required this.totalInvites,
  });

  final int pendingInvites;
  final int acceptedInvites;
  final int expiredInvites;
  final int activeMembers;
  final int interventionCount;
  final int totalMembers;
  final int totalInvites;

  int get total => totalMembers + totalInvites;

  static const empty = UyeliklerSummaryStrip(
    pendingInvites: 0,
    acceptedInvites: 0,
    expiredInvites: 0,
    activeMembers: 0,
    interventionCount: 0,
    totalMembers: 0,
    totalInvites: 0,
  );
}

class UyelikRowViewModel {
  const UyelikRowViewModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.detailLine,
    required this.statusLabel,
    required this.durum,
    required this.tone,
    required this.timestampLabel,
    required this.occurredAt,
    required this.needsAction,
    required this.hasPartialMetadata,
    // Davet meta
    this.inviteId,
    this.inviteCode,
    this.isActiveInvite = false,
    // Üye meta
    this.memberUserId,
    this.isSelf = false,
    this.canModerate = false,
    this.canSuspend = false,
    this.canRemove = false,
  });

  final String id;
  final UyelikKind kind;
  final String title;
  final String subtitle;
  final String detailLine;
  final String statusLabel;
  final UyelikDurum durum;
  final UyelikTone tone;
  final String timestampLabel;
  final DateTime? occurredAt;
  final bool needsAction;
  final bool hasPartialMetadata;

  final String? inviteId;
  final String? inviteCode;
  final bool isActiveInvite;

  final String? memberUserId;
  final bool isSelf;
  final bool canModerate;
  final bool canSuspend;
  final bool canRemove;
}

class UyeliklerPageSnapshot {
  const UyeliklerPageSnapshot({
    required this.rows,
    required this.strip,
    required this.isEmpty,
    required this.hasInvites,
    required this.hasMembers,
    required this.coverageNote,
  });

  final List<UyelikRowViewModel> rows;
  final UyeliklerSummaryStrip strip;
  final bool isEmpty;
  final bool hasInvites;
  final bool hasMembers;
  final String coverageNote;
}
