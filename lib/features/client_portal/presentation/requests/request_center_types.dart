// Talep Merkezi — yalnızca GERÇEK sinyaller: auth/profil durumu ve gerçek
// navigasyon/iletişim kanalları (talep başlatma=mesaj, keşfet, danışman,
// profil). Sunucuda izlenen kayıtlı talep verisi YOK; bu nedenle uydurma talep
// satırı, sahte talep durumu, icat edilmiş danışman eşleşmesi veya AI eşleşme
// skoru GÖSTERİLMEZ. Kayıtlı talep altyapısı yokken kanallar ve dürüst boş/
// "yakında" durumu sunulur.

import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';

/// Yatay filtreler — yalnızca grounded kanal durumları. (Konut/Arsa/İşyeri gibi
/// tür filtreleri, sunucuda tipli gerçek talep tutulmadığı için bilinçli olarak
/// gösterilmez — daima boş dönecek bir filtre dürüst değildir.)
enum RequestCenterFilter { all, active, draft, message }

extension RequestCenterFilterLabel on RequestCenterFilter {
  String get label => switch (this) {
        RequestCenterFilter.all => 'Tümü',
        RequestCenterFilter.active => 'Hazır',
        RequestCenterFilter.draft => 'Yakında',
        RequestCenterFilter.message => 'Mesaj',
      };
}

/// Kanal türü (ikon eşlemesi).
enum RequestKind { create, explore, advisor, preferences }

/// Renk tonu — widget katmanında tema rengine eşlenir.
enum RequestTone { accent, info, success, warning, neutral }

/// Kanal hazır mı? ready = gerçek aksiyon çalışır; preview = altyapı yakında;
/// blocked = giriş/önkoşul gerekli. Hiçbiri uydurma değildir.
enum RequestReadiness { ready, preview, blocked }

class RequestCenterEntry {
  const RequestCenterEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.typeLabel,
    required this.detail,
    required this.context,
    required this.statusLabel,
    required this.tone,
    required this.readiness,
    required this.actionLabel,
    required this.shortcut,
    required this.searchText,
    required this.isReady,
    required this.isPreview,
    required this.isMessage,
  });

  final String id;
  final RequestKind kind;
  final String title;

  /// Aksiyon türü etiketi (ör. "Talep", "Keşif", "İletişim").
  final String typeLabel;
  final String detail;

  /// Kaynak/bağlam satırı (dürüst kapsam).
  final String context;

  final String statusLabel;
  final RequestTone tone;
  final RequestReadiness readiness;

  /// Tek somut sonraki adım (dead button yok — daima gerçek bir kabuk sekmesi).
  final String actionLabel;
  final MainShellShortcut shortcut;

  final String searchText;

  final bool isReady;
  final bool isPreview;
  final bool isMessage;

  bool get needsAttention => readiness != RequestReadiness.ready;
}

class RequestCenterSummary {
  const RequestCenterSummary({
    required this.savedRequests,
    required this.activeChannels,
    required this.messageReady,
    required this.requestPreview,
    required this.profileReady,
  });

  /// Sunucuda tutulan kayıtlı talep sayısı (altyapı yok → 0, dürüst).
  final int savedRequests;

  /// readiness == ready olan gerçek çalışan kanal sayısı.
  final int activeChannels;

  final bool messageReady;

  /// Otomatik talep kaydı henüz yok → daima true (dürüst "yakında").
  final bool requestPreview;

  final bool profileReady;

  static const empty = RequestCenterSummary(
    savedRequests: 0,
    activeChannels: 0,
    messageReady: false,
    requestPreview: true,
    profileReady: false,
  );
}

class RequestCenterSnapshot {
  const RequestCenterSnapshot({
    required this.entries,
    required this.summary,
    required this.signedIn,
    required this.greetingName,
    required this.coverageNote,
    required this.isEmpty,
  });

  final List<RequestCenterEntry> entries;
  final RequestCenterSummary summary;
  final bool signedIn;

  /// Gerçek profil adı (varsa); yoksa boş — uydurma isim yok.
  final String greetingName;

  final String coverageNote;
  final bool isEmpty;
}
