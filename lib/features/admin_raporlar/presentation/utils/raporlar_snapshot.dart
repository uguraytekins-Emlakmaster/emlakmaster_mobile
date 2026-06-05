import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';

/// Erişim yetkisi (RBAC) + canlı snapshot sayımlarından tek türetilmiş hub.
/// Tamamen saf/test edilebilir; sağlanmayan grounded sinyaller sessizce gizlenir.
RaporlarSnapshot computeRaporlarSnapshot({
  required AppRole role,
  RaporlarGroundedSignals signals = RaporlarGroundedSignals.empty,
}) {
  final entries = <RaporEntryViewModel>[];

  final canReports = FeaturePermission.canViewReports(role);
  final canTeams = FeaturePermission.canManageTeams(role);
  final canMemberships =
      FeaturePermission.canInviteAgents(role) || canTeams;
  final canAudit = FeaturePermission.canViewAuditLog(role);
  final canConnections = FeaturePermission.canManagePlatformIntegrations(role);
  final canCallCenter = FeaturePermission.canViewCallCenter(role);
  final canWarRoom = FeaturePermission.canViewWarRoom(role);

  // ——— Kadro ———
  if (canReports || FeaturePermission.canManageConsultants(role) || canTeams) {
    entries.add(
      _entry(
        id: 'kadro',
        kategori: RaporKategori.kadro,
        title: 'Kadro ve yetkiler',
        scope: 'Danışman dizini',
        description: 'Danışmanlar, ekip dağılımı ve erişim ayarları',
        actionKind: RaporActionKind.route,
        route: AppRouter.routeAdminConsultants,
        readinessLabel: 'Hazır',
        tone: RaporTone.neutral,
      ),
    );
  }

  // ——— Ekipler ———
  if (canTeams) {
    final teams = signals.teamsCount;
    final hasTeams = teams != null && teams > 0;
    entries.add(
      _entry(
        id: 'ekip',
        kategori: RaporKategori.ekip,
        title: 'Ekipler',
        scope: teams == null
            ? 'Ekip yapısı'
            : (hasTeams ? '$teams ekip kaydı' : 'Ekip kurulumu bekleniyor'),
        description: 'Kurulum, lider ataması ve ekip yapısı',
        actionKind: RaporActionKind.route,
        route: AppRouter.routeAdminTeams,
        readinessLabel: teams == null
            ? 'Hazır'
            : (hasTeams ? 'Hazır' : 'Kurulum bekliyor'),
        tone: (teams != null && !hasTeams) ? RaporTone.info : RaporTone.neutral,
      ),
    );
  }

  // ——— İşlem Kayıtları (Audit) ———
  if (canAudit) {
    entries.add(
      _entry(
        id: 'audit',
        kategori: RaporKategori.audit,
        title: 'İşlem kayıtları',
        scope: 'Operasyon geçmişi',
        description: 'Davet, üyelik ve denetim kayıtları tek akışta',
        actionKind: RaporActionKind.route,
        route: AppRouter.routeAdminAudit,
        readinessLabel: 'Canlı',
        tone: RaporTone.success,
      ),
    );
  }

  // ——— Üyelikler / Davetler ———
  if (canMemberships) {
    final pending = signals.officeKnown ? signals.officePendingInvites : null;
    entries.add(
      _entry(
        id: 'uyelik',
        kategori: RaporKategori.uyelik,
        title: 'Üyelikler / Davetler',
        scope: (pending != null && pending > 0)
            ? '$pending bekleyen davet'
            : 'Davet ve katılım',
        description: 'Davet, onboarding ve katılım takibi tek yüzeyde',
        actionKind: RaporActionKind.route,
        route: AppRouter.routeAdminMemberships,
        readinessLabel: 'Hazır',
        tone: RaporTone.neutral,
      ),
    );
  }

  // ——— Ofis Masası ———
  if (canTeams || canMemberships) {
    final intervention = signals.officeKnown ? signals.officeIntervention : null;
    final needs = intervention != null && intervention > 0;
    entries.add(
      _entry(
        id: 'ofis',
        kategori: RaporKategori.ofis,
        title: 'Ofis Masası',
        scope: 'Üyeler, davetler ve bağlantılar',
        description: 'Ofis durumu ve operasyon kontrol yüzeyi',
        actionKind: RaporActionKind.route,
        route: AppRouter.routeOfficeAdmin,
        readinessLabel: needs ? 'Müdahale gerekli' : 'Hazır',
        tone: needs ? RaporTone.warning : RaporTone.neutral,
        needsAction: needs,
        attentionCount: needs ? intervention : 0,
        attentionLabel: needs ? '$intervention müdahale' : null,
      ),
    );
  }

  // ——— Bağlantılar ———
  if (canConnections) {
    final intervention =
        signals.connectionKnown ? signals.connectionIntervention : null;
    final ready = signals.connectionKnown ? signals.connectionReady : null;
    final needs = intervention != null && intervention > 0;
    entries.add(
      _entry(
        id: 'baglanti',
        kategori: RaporKategori.baglanti,
        title: 'Bağlantılar',
        scope: (ready != null && ready > 0)
            ? '$ready hazır platform'
            : 'Platform durumu',
        description: 'Platform durumu ve ofis entegrasyon kontrolü',
        actionKind: RaporActionKind.route,
        route: AppRouter.routeConnectedAccounts,
        readinessLabel: needs
            ? 'Müdahale gerekli'
            : ((ready != null && ready > 0) ? 'Hazır' : 'Kurulum'),
        tone: needs
            ? RaporTone.warning
            : ((ready != null && ready > 0)
                ? RaporTone.success
                : RaporTone.neutral),
        needsAction: needs,
        attentionCount: needs ? intervention : 0,
        attentionLabel: needs ? '$intervention müdahale' : null,
      ),
    );
  }

  // ——— Komuta Merkezi ———
  if (canCallCenter) {
    entries.add(
      _entry(
        id: 'komuta_merkezi',
        kategori: RaporKategori.komuta,
        title: 'Komuta Merkezi',
        scope: 'Çağrı ve danışman görünümleri',
        description: 'Danışman, müşteri ve kayıt görünümleri tek yerde',
        actionKind: RaporActionKind.commandCenterTab,
        readinessLabel: 'Canlı',
        tone: RaporTone.info,
      ),
    );
  }

  // ——— Komuta Odası (War Room) ———
  if (canWarRoom) {
    entries.add(
      _entry(
        id: 'komuta_odasi',
        kategori: RaporKategori.komuta,
        title: 'Komuta Odası',
        scope: 'Operasyon savaş odası',
        description: 'Canlı operasyon ve öncelik görünümü',
        actionKind: RaporActionKind.warRoomTab,
        readinessLabel: 'Canlı',
        tone: RaporTone.info,
      ),
    );
  }

  // Müdahale gereken yüzeyler öne; aksi halde tanım sırası korunur (stabil).
  final ordered = <RaporEntryViewModel>[
    ...entries.where((e) => e.needsAction),
    ...entries.where((e) => !e.needsAction),
  ];

  final auditLive = entries.any((e) => e.kategori == RaporKategori.audit);
  final summary = RaporlarSummary(
    activeSurfaces: entries.length,
    interventionAreas: entries.where((e) => e.needsAction).length,
    teamsCount: signals.teamsCount,
    pendingInvites: signals.officeKnown ? signals.officePendingInvites : null,
    connectionIntervention:
        signals.connectionKnown ? signals.connectionIntervention : null,
    auditLive: auditLive,
  );

  return RaporlarSnapshot(
    entries: ordered,
    summary: summary,
    coverageNote:
        'Yüzeyler erişim yetkinizden, sayımlar yalnızca canlı snapshot '
        'verisinden türetilir. Uydurma rapor toplamı, sahte grafik veya trend yok.',
    isEmpty: ordered.isEmpty,
  );
}

RaporEntryViewModel _entry({
  required String id,
  required RaporKategori kategori,
  required String title,
  required String scope,
  required String description,
  required RaporActionKind actionKind,
  required String readinessLabel,
  required RaporTone tone,
  String? route,
  bool needsAction = false,
  int attentionCount = 0,
  String? attentionLabel,
}) {
  final search = [
    title,
    scope,
    description,
    _kategoriLabel(kategori),
    readinessLabel,
  ].join(' ').toLowerCase();
  return RaporEntryViewModel(
    id: id,
    kategori: kategori,
    title: title,
    scope: scope,
    description: description,
    actionKind: actionKind,
    route: route,
    readinessLabel: readinessLabel,
    tone: tone,
    needsAction: needsAction,
    attentionCount: attentionCount,
    attentionLabel: attentionLabel,
    searchText: search,
  );
}

String _kategoriLabel(RaporKategori k) => switch (k) {
      RaporKategori.kadro => 'kadro',
      RaporKategori.ekip => 'ekip',
      RaporKategori.audit => 'audit işlem kayıtları',
      RaporKategori.uyelik => 'üyelik davet',
      RaporKategori.ofis => 'ofis masası',
      RaporKategori.baglanti => 'bağlantı entegrasyon',
      RaporKategori.komuta => 'komuta',
    };
