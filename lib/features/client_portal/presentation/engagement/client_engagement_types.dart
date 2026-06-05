// İlgi & Etkileşim — yalnızca GERÇEK sinyaller: auth/profil durumu, önizleme
// portföy sayımı ve gerçek navigasyon kanalları (Keşfet, Mesaj, Sanal tur,
// Profil). Uydurma ilgi skoru, sahte "AI öneri", icat edilmiş gezinme/randevu/
// mesaj olayı veya sahte trend YOK. Sunucuda izlenmeyen sinyaller dürüstçe
// "yakında/kısmi" olarak işaretlenir.

import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';

/// Yatay filtreler (yalnızca grounded kategoriler / kapsam durumları).
enum EngagementFilter {
  all,
  interaction,
  favorites,
  message,
  request,
  saved,
  recent,
  partial,
}

extension EngagementFilterLabel on EngagementFilter {
  String get label => switch (this) {
        EngagementFilter.all => 'Tümü',
        EngagementFilter.interaction => 'Etkileşim',
        EngagementFilter.favorites => 'Favoriler',
        EngagementFilter.message => 'Mesaj',
        EngagementFilter.request => 'Talep',
        EngagementFilter.saved => 'Kayıtlı',
        EngagementFilter.recent => 'Son 7g',
        EngagementFilter.partial => 'Kısmi',
      };
}

/// Kanal türü (ikon + filtre eşlemesi).
enum EngagementKind {
  discovery,
  favorites,
  message,
  request,
  tour,
  requestCenter,
  profile,
}

/// Renk tonu — widget katmanında tema rengine eşlenir.
enum EngagementTone { accent, info, success, warning, neutral }

/// Kanal hazır mı? ready = gerçek aksiyon çalışır; preview = altyapı yakında;
/// blocked = giriş/önkoşul gerekli. Hiçbiri uydurma değildir.
enum EngagementReadiness { ready, preview, blocked }

class ClientEngagementEntry {
  const ClientEngagementEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.actionType,
    required this.detail,
    required this.context,
    required this.statusLabel,
    required this.tone,
    required this.readiness,
    required this.actionLabel,
    required this.shortcut,
    required this.searchText,
    // Filtre için önceden hesaplanmış bayraklar
    required this.isInteraction,
    required this.isSaved,
    required this.isRecent,
  });

  final String id;
  final EngagementKind kind;
  final String title;

  /// Aksiyon türü etiketi (ör. "Keşif", "İletişim").
  final String actionType;
  final String detail;

  /// Kaynak/bağlam satırı (ör. "Önizleme portföy · canlı bağlantı yakında").
  final String context;

  final String statusLabel;
  final EngagementTone tone;
  final EngagementReadiness readiness;

  /// Tek somut sonraki adım (dead button yok — daima gerçek bir kabuk sekmesi).
  final String actionLabel;
  final MainShellShortcut shortcut;

  final String searchText;

  final bool isInteraction;
  final bool isSaved;
  final bool isRecent;

  bool get needsAttention => readiness != EngagementReadiness.ready;
}

class ClientEngagementSummary {
  const ClientEngagementSummary({
    required this.previewPortfolio,
    required this.activeChannels,
    required this.favoriteCount,
    required this.messageReady,
    required this.requestPreview,
    required this.profileReady,
  });

  /// Gerçek önizleme portföy ilan sayısı.
  final int previewPortfolio;

  /// readiness == ready olan gerçek çalışan kanal sayısı.
  final int activeChannels;

  /// Sunucuda tutulan favori sayısı (henüz izlenmiyor → 0, dürüst).
  final int favoriteCount;

  final bool messageReady;
  final bool requestPreview;
  final bool profileReady;

  static const empty = ClientEngagementSummary(
    previewPortfolio: 0,
    activeChannels: 0,
    favoriteCount: 0,
    messageReady: false,
    requestPreview: true,
    profileReady: false,
  );
}

class ClientEngagementSnapshot {
  const ClientEngagementSnapshot({
    required this.entries,
    required this.summary,
    required this.signedIn,
    required this.greetingName,
    required this.coverageNote,
    required this.isEmpty,
  });

  final List<ClientEngagementEntry> entries;
  final ClientEngagementSummary summary;
  final bool signedIn;

  /// Gerçek profil adı (varsa); yoksa boş — uydurma isim yok.
  final String greetingName;

  final String coverageNote;
  final bool isEmpty;
}
