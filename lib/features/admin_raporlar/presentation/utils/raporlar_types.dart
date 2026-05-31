// Raporlar — yalnızca gerçek erişim noktaları (RBAC) + canlı snapshot sayımlarından
// türetilen executive hub tipleri. Uydurma grafik, sahte trend veya icat edilmiş
// rapor toplamı yok.

/// Rapor yüzeyi kategorisi (filtre + ikon eşlemesi).
enum RaporKategori { kadro, ekip, audit, uyelik, ofis, baglanti, komuta }

/// Açılış biçimi: GoRouter rotası veya kabuk sekmesi.
enum RaporActionKind { route, commandCenterTab, warRoomTab }

/// Renk tonu — widget katmanında tema rengine eşlenir.
enum RaporTone { info, success, warning, danger, neutral }

/// Yatay filtreler.
enum RaporlarFilter {
  all,
  kadro,
  ekip,
  audit,
  uyelik,
  ofis,
  baglanti,
  intervention,
  ready,
}

extension RaporlarFilterLabel on RaporlarFilter {
  String get label => switch (this) {
        RaporlarFilter.all => 'Tümü',
        RaporlarFilter.kadro => 'Kadro',
        RaporlarFilter.ekip => 'Ekip',
        RaporlarFilter.audit => 'Audit',
        RaporlarFilter.uyelik => 'Üyelik',
        RaporlarFilter.ofis => 'Ofis',
        RaporlarFilter.baglanti => 'Bağlantı',
        RaporlarFilter.intervention => 'Müdahale',
        RaporlarFilter.ready => 'Hazır',
      };
}

/// Sayfaya dışarıdan verilen, yalnızca canlı/yüklenmiş olduğunda dolu gelen
/// grounded sinyaller. Hiçbiri uydurma değildir; null → sessiz gizleme.
class RaporlarGroundedSignals {
  const RaporlarGroundedSignals({
    this.teamsCount,
    this.officePendingInvites,
    this.officeIntervention,
    this.officeKnown = false,
    this.connectionIntervention,
    this.connectionReady,
    this.connectionKnown = false,
  });

  final int? teamsCount;
  final int? officePendingInvites;
  final int? officeIntervention;
  final bool officeKnown;
  final int? connectionIntervention;
  final int? connectionReady;
  final bool connectionKnown;

  static const empty = RaporlarGroundedSignals();
}

class RaporEntryViewModel {
  const RaporEntryViewModel({
    required this.id,
    required this.kategori,
    required this.title,
    required this.scope,
    required this.description,
    required this.actionKind,
    required this.readinessLabel,
    required this.tone,
    required this.needsAction,
    required this.searchText,
    this.route,
    this.attentionCount = 0,
    this.attentionLabel,
  });

  final String id;
  final RaporKategori kategori;
  final String title;
  final String scope;
  final String description;
  final RaporActionKind actionKind;

  /// GoRouter rotası (actionKind == route ise dolu).
  final String? route;

  final String readinessLabel;
  final RaporTone tone;
  final bool needsAction;
  final int attentionCount;
  final String? attentionLabel;
  final String searchText;
}

class RaporlarSummary {
  const RaporlarSummary({
    required this.activeSurfaces,
    required this.interventionAreas,
    required this.teamsCount,
    required this.pendingInvites,
    required this.connectionIntervention,
    required this.auditLive,
  });

  final int activeSurfaces;
  final int interventionAreas;

  /// Grounded değilse null (sessiz gizleme).
  final int? teamsCount;
  final int? pendingInvites;
  final int? connectionIntervention;

  final bool auditLive;

  static const empty = RaporlarSummary(
    activeSurfaces: 0,
    interventionAreas: 0,
    teamsCount: null,
    pendingInvites: null,
    connectionIntervention: null,
    auditLive: false,
  );
}

class RaporlarSnapshot {
  const RaporlarSnapshot({
    required this.entries,
    required this.summary,
    required this.coverageNote,
    required this.isEmpty,
  });

  final List<RaporEntryViewModel> entries;
  final RaporlarSummary summary;
  final String coverageNote;
  final bool isEmpty;
}
