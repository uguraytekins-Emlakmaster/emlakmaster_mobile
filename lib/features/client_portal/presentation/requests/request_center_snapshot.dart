import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_types.dart';

/// Saf/test edilebilir türetme. Tüm gösterim metni burada önceden hesaplanır;
/// build() içinde pahalı string/format işi yapılmaz. Yalnızca gerçek sinyaller:
/// auth durumu ve gerçek kabuk sekmesi / iletişim kanalları. Kayıtlı talep
/// altyapısı olmadığından gerçek talep satırı üretilmez — kanallar + dürüst
/// "kayıt yakında" durumu döner.
RequestCenterSnapshot computeRequestCenterSnapshot({
  required bool signedIn,
  String? displayName,
}) {
  final greeting = (displayName ?? '').trim();

  final entries = <RequestCenterEntry>[
    _entry(
      id: 'create',
      kind: RequestKind.create,
      title: 'Talep oluştur',
      typeLabel: 'Talep',
      detail: 'Aradığınız konut/işyeri kriterlerini danışmanınıza iletin',
      context: 'Otomatik talep kaydı yakında · şimdilik mesajdan iletilir',
      statusLabel: 'Yakında',
      tone: RequestTone.warning,
      readiness: RequestReadiness.preview,
      actionLabel: 'Mesajdan ilet',
      shortcut: MainShellShortcut.openMessagesTab,
      isReady: false,
      isPreview: true,
      isMessage: true,
    ),
    _entry(
      id: 'explore',
      kind: RequestKind.explore,
      title: 'Keşfet’e git',
      typeLabel: 'Keşif',
      detail: 'Size uygun olabilecek ilanları inceleyin',
      context: 'Önizleme portföy hazır · canlı portföy yakında',
      statusLabel: 'Hazır',
      tone: RequestTone.info,
      readiness: RequestReadiness.ready,
      actionLabel: 'Keşfet’e git',
      shortcut: MainShellShortcut.openHomeTab,
      isReady: true,
      isPreview: false,
      isMessage: false,
    ),
    _entry(
      id: 'advisor',
      kind: RequestKind.advisor,
      title: 'Danışmana ulaş',
      typeLabel: 'İletişim',
      detail: 'Talebiniz için danışmanınıza doğrudan yazın',
      context: 'Mesaj kanalı hazır · gerçek iletişim',
      statusLabel: 'Hazır',
      tone: RequestTone.success,
      readiness: RequestReadiness.ready,
      actionLabel: 'Mesaj gönder',
      shortcut: MainShellShortcut.openMessagesTab,
      isReady: true,
      isPreview: false,
      isMessage: true,
    ),
    _entry(
      id: 'preferences',
      kind: RequestKind.preferences,
      title: 'Tercihlerim',
      typeLabel: 'Hesap',
      detail: 'Hesap ve iletişim tercihlerinizi yönetin',
      context: signedIn ? 'Oturum aktif · hazır' : 'Görüntülemek için giriş yapın',
      statusLabel: signedIn ? 'Hazır' : 'Giriş gerekli',
      tone: signedIn ? RequestTone.success : RequestTone.neutral,
      readiness:
          signedIn ? RequestReadiness.ready : RequestReadiness.blocked,
      actionLabel: 'Profili aç',
      shortcut: MainShellShortcut.openAccountTab,
      isReady: signedIn,
      isPreview: false,
      isMessage: false,
    ),
  ];

  final activeChannels =
      entries.where((e) => e.readiness == RequestReadiness.ready).length;

  final summary = RequestCenterSummary(
    savedRequests: 0,
    activeChannels: activeChannels,
    messageReady: true,
    requestPreview: true,
    profileReady: signedIn,
  );

  return RequestCenterSnapshot(
    entries: entries,
    summary: summary,
    signedIn: signedIn,
    greetingName: greeting,
    coverageNote:
        'Kayıtlı talep, talep durumu ve danışman eşleşmesi henüz sunucuda '
        'tutulmuyor; yalnızca gerçek kanallar gösterilir. Uydurma talep veya '
        'eşleşme skoru gösterilmez.',
    isEmpty: entries.isEmpty,
  );
}

RequestCenterEntry _entry({
  required String id,
  required RequestKind kind,
  required String title,
  required String typeLabel,
  required String detail,
  required String context,
  required String statusLabel,
  required RequestTone tone,
  required RequestReadiness readiness,
  required String actionLabel,
  required MainShellShortcut shortcut,
  required bool isReady,
  required bool isPreview,
  required bool isMessage,
}) {
  final search = [
    title,
    typeLabel,
    detail,
    context,
    statusLabel,
  ].join(' ').toLowerCase();
  return RequestCenterEntry(
    id: id,
    kind: kind,
    title: title,
    typeLabel: typeLabel,
    detail: detail,
    context: context,
    statusLabel: statusLabel,
    tone: tone,
    readiness: readiness,
    actionLabel: actionLabel,
    shortcut: shortcut,
    searchText: search,
    isReady: isReady,
    isPreview: isPreview,
    isMessage: isMessage,
  );
}
