// Ofis Masası — yalnızca gerçek office_memberships + office_invites +
// platform_setups metadata'sından türetilen tipler. Uydurma bağlantı sağlığı,
// sahte senkron veya onboarding durumu yok.

/// Satır türü: üyelik, davet veya platform bağlantısı (kurulum kaydı).
enum OfisRowKind { member, invite, connection }

/// Renk tonu — widget katmanında tema rengine eşlenir.
enum OfisTone { info, success, warning, danger, neutral }

/// Ofis özet şeridi — yalnızca gerçek, türetilmiş sayımlar.
class OfisMasasiSummary {
  const OfisMasasiSummary({
    required this.activeMembers,
    required this.pendingInvites,
    required this.suspendedMembers,
    required this.connectionsReady,
    required this.connectionsNeedingSetup,
    required this.interventionCount,
    required this.totalMembers,
    required this.totalInvites,
    required this.totalConnections,
    required this.connectionsKnown,
  });

  final int activeMembers;
  final int pendingInvites;
  final int suspendedMembers;

  /// Kurulumu "hazır" sayılan platform sayısı (readyForImport / liveEnabled).
  final int connectionsReady;

  /// Henüz hazır olmayan platform sayısı (kurulum gerekli / sürüyor).
  final int connectionsNeedingSetup;

  /// Müdahale gereken toplam: askıdaki üye + süresi dolan/kontenjanı dolan davet
  /// + dikkat gerektiren bağlantı.
  final int interventionCount;

  final int totalMembers;
  final int totalInvites;
  final int totalConnections;

  /// Platform kurulum verisi yüklendiyse true; yükleniyor/hata ise false
  /// (bağlantı metrikleri dürüstçe gizlenir).
  final bool connectionsKnown;

  static const empty = OfisMasasiSummary(
    activeMembers: 0,
    pendingInvites: 0,
    suspendedMembers: 0,
    connectionsReady: 0,
    connectionsNeedingSetup: 0,
    interventionCount: 0,
    totalMembers: 0,
    totalInvites: 0,
    totalConnections: 0,
    connectionsKnown: false,
  );
}

class OfisRowViewModel {
  const OfisRowViewModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.detailLine,
    required this.statusLabel,
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
    this.canSuspend = false,
    this.canRemove = false,
    // Bağlantı meta
    this.connectionPlatformKey,
    this.connectionConfigured = false,
  });

  final String id;
  final OfisRowKind kind;
  final String title;
  final String subtitle;
  final String detailLine;
  final String statusLabel;
  final OfisTone tone;
  final String timestampLabel;
  final DateTime? occurredAt;
  final bool needsAction;
  final bool hasPartialMetadata;

  final String? inviteId;
  final String? inviteCode;
  final bool isActiveInvite;

  final String? memberUserId;
  final bool isSelf;
  final bool canSuspend;
  final bool canRemove;

  final String? connectionPlatformKey;

  /// Firestore'da gerçek bir kurulum kaydı var mı (yalnızca katalog değil).
  final bool connectionConfigured;
}

class OfisMasasiSnapshot {
  const OfisMasasiSnapshot({
    required this.members,
    required this.invites,
    required this.connections,
    required this.summary,
    required this.coverageNote,
    required this.connectionsNote,
    required this.connectionsKnown,
    required this.isEmpty,
  });

  final List<OfisRowViewModel> members;
  final List<OfisRowViewModel> invites;
  final List<OfisRowViewModel> connections;
  final OfisMasasiSummary summary;
  final String coverageNote;
  final String connectionsNote;

  /// Platform kurulum verisi yüklendiyse true.
  final bool connectionsKnown;

  /// Üye + davet kaydı yoksa true (bağlantılar katalogdan her zaman gelir).
  final bool isEmpty;

  /// Tüm satırlar (arama/filtre yardımcıları için).
  List<OfisRowViewModel> get allRows => [...members, ...invites, ...connections];
}
