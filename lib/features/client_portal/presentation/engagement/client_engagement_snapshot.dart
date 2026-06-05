import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_types.dart';

/// Saf/test edilebilir türetme. Tüm gösterim metni burada önceden hesaplanır;
/// build() içinde pahalı string/format işi yapılmaz. Yalnızca gerçek sinyaller:
/// auth durumu, önizleme portföy sayımı ve gerçek kabuk sekmesi kanalları.
ClientEngagementSnapshot computeClientEngagementSnapshot({
  required bool signedIn,
  String? displayName,
  required int previewPortfolioCount,
}) {
  final greeting = (displayName ?? '').trim();

  final entries = <ClientEngagementEntry>[
    _entry(
      id: 'discovery',
      kind: EngagementKind.discovery,
      title: 'Önizleme portföyü',
      actionType: 'Keşif',
      detail: 'Size özel hazırlanan örnek ilanları inceleyin',
      context: previewPortfolioCount > 0
          ? '$previewPortfolioCount önizleme ilanı · canlı portföy yakında'
          : 'Canlı portföy bağlantısı yakında',
      statusLabel: previewPortfolioCount > 0
          ? '$previewPortfolioCount ilan'
          : 'Hazır',
      tone: EngagementTone.info,
      readiness: EngagementReadiness.ready,
      actionLabel: 'Keşfet’e git',
      shortcut: MainShellShortcut.openHomeTab,
      isInteraction: true,
      isSaved: false,
      isRecent: false,
    ),
    _entry(
      id: 'message',
      kind: EngagementKind.message,
      title: 'Danışmana mesaj',
      actionType: 'İletişim',
      detail: 'Sorularınız için danışmanınıza doğrudan ulaşın',
      context: 'Mesaj kanalı hazır · gerçek iletişim',
      statusLabel: 'Hazır',
      tone: EngagementTone.success,
      readiness: EngagementReadiness.ready,
      actionLabel: 'Mesaj gönder',
      shortcut: MainShellShortcut.openMessagesTab,
      isInteraction: true,
      isSaved: false,
      isRecent: false,
    ),
    _entry(
      id: 'request_center',
      kind: EngagementKind.requestCenter,
      title: 'Talep merkezi',
      actionType: 'Talep',
      detail: 'Kayıtlı talepleriniz ve sonraki adımları görün',
      context: 'Talep merkezi hazır · kayıt yakında',
      statusLabel: 'Hazır',
      tone: EngagementTone.accent,
      readiness: EngagementReadiness.ready,
      actionLabel: 'Talep merkezini aç',
      shortcut: MainShellShortcut.openRequestsTab,
      isInteraction: true,
      isSaved: false,
      isRecent: false,
    ),
    _entry(
      id: 'favorites',
      kind: EngagementKind.favorites,
      title: 'Favori ilanlar',
      actionType: 'Kayıtlı ilgi',
      detail: 'Beğendiğiniz ilanları kaydedin',
      context: 'Favori kaydı henüz sunucuda tutulmuyor',
      statusLabel: 'Yakında',
      tone: EngagementTone.warning,
      readiness: EngagementReadiness.preview,
      actionLabel: 'İlanlara göz at',
      shortcut: MainShellShortcut.openHomeTab,
      isInteraction: false,
      isSaved: true,
      isRecent: false,
    ),
    _entry(
      id: 'request',
      kind: EngagementKind.request,
      title: 'Randevu / talep',
      actionType: 'Talep',
      detail: 'Görüşme veya bilgi talebinizi iletin',
      context: 'Otomatik talep iletimi yakında · şimdilik mesajdan',
      statusLabel: 'Yakında',
      tone: EngagementTone.warning,
      readiness: EngagementReadiness.preview,
      actionLabel: 'Mesajdan ilet',
      shortcut: MainShellShortcut.openMessagesTab,
      isInteraction: false,
      isSaved: false,
      isRecent: false,
    ),
    _entry(
      id: 'profile',
      kind: EngagementKind.profile,
      title: 'Profilim',
      actionType: 'Hesap',
      detail: 'Hesap ve tercih merkezinizi yönetin',
      context: signedIn ? 'Oturum aktif · hazır' : 'Görüntülemek için giriş yapın',
      statusLabel: signedIn ? 'Hazır' : 'Giriş gerekli',
      tone: signedIn ? EngagementTone.success : EngagementTone.neutral,
      readiness:
          signedIn ? EngagementReadiness.ready : EngagementReadiness.blocked,
      actionLabel: 'Profili aç',
      shortcut: MainShellShortcut.openAccountTab,
      isInteraction: true,
      isSaved: false,
      isRecent: false,
    ),
  ];

  final activeChannels =
      entries.where((e) => e.readiness == EngagementReadiness.ready).length;

  final summary = ClientEngagementSummary(
    previewPortfolio: previewPortfolioCount,
    activeChannels: activeChannels,
    favoriteCount: 0,
    messageReady: true,
    requestPreview: true,
    profileReady: signedIn,
  );

  return ClientEngagementSnapshot(
    entries: entries,
    summary: summary,
    signedIn: signedIn,
    greetingName: greeting,
    coverageNote:
        'Favori kaydı, randevu/talep ve son etkileşim geçmişi henüz sunucuda '
        'tutulmuyor; yalnızca gerçek kanallar ve önizleme portföyü gösterilir.',
    isEmpty: entries.isEmpty,
  );
}

ClientEngagementEntry _entry({
  required String id,
  required EngagementKind kind,
  required String title,
  required String actionType,
  required String detail,
  required String context,
  required String statusLabel,
  required EngagementTone tone,
  required EngagementReadiness readiness,
  required String actionLabel,
  required MainShellShortcut shortcut,
  required bool isInteraction,
  required bool isSaved,
  required bool isRecent,
}) {
  final search = [
    title,
    actionType,
    detail,
    context,
    statusLabel,
  ].join(' ').toLowerCase();
  return ClientEngagementEntry(
    id: id,
    kind: kind,
    title: title,
    actionType: actionType,
    detail: detail,
    context: context,
    statusLabel: statusLabel,
    tone: tone,
    readiness: readiness,
    actionLabel: actionLabel,
    shortcut: shortcut,
    searchText: search,
    isInteraction: isInteraction,
    isSaved: isSaved,
    isRecent: isRecent,
  );
}
