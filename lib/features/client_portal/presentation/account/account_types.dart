// Hesabım / Profil — yalnızca GERÇEK hesap sinyalleri: Firebase auth (e-posta,
// görünen ad, oturum, e-posta doğrulama, üyelik tarihi) ve Firestore users/{uid}
// (ad, rol). Telefon yalnızca gerçekten kayıtlıysa gösterilir; profil düzenleme,
// kayıtlı tercih geçmişi ve gelişmiş ayarlar sunucuda tutulmadığından uydurma
// alan/doğrulama/analitik GÖSTERİLMEZ; eksik alanlar dürüstçe "Kayıtlı değil /
// Yakında" olarak işaretlenir.

import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:flutter/widgets.dart';

/// Bölümler (section rhythm). Filtre kategorileriyle eşlenir.
enum AccountSection { account, contact, channels, privacy, session }

extension AccountSectionLabel on AccountSection {
  String get label => switch (this) {
        AccountSection.account => 'Hesap',
        AccountSection.contact => 'İletişim',
        AccountSection.channels => 'Hızlı geçiş',
        AccountSection.privacy => 'Gizlilik & destek',
        AccountSection.session => 'Oturum',
      };
}

/// Yatay filtreler — yalnızca grounded kategoriler + dürüst "Kısmi".
enum AccountFilter { all, account, contact, channels, privacy, partial }

extension AccountFilterLabel on AccountFilter {
  String get label => switch (this) {
        AccountFilter.all => 'Tümü',
        AccountFilter.account => 'Hesap',
        AccountFilter.contact => 'İletişim',
        AccountFilter.channels => 'Kanallar',
        AccountFilter.privacy => 'Gizlilik',
        AccountFilter.partial => 'Kısmi',
      };
}

enum AccountTone { accent, info, success, warning, neutral, danger }

/// ready = gerçek/çalışır; partial = alan sunucuda yok (dürüst); blocked =
/// giriş gerekli. Hiçbiri uydurma değildir.
enum AccountReadiness { ready, partial, blocked }

/// Satır dokunma davranışı — dağıtım [AccountActions] tarafından yapılır.
enum AccountAction {
  detail,
  goMessages,
  goRequests,
  goEngagement,
  privacy,
  about,
  signOut,
}

class AccountEntry {
  const AccountEntry({
    required this.id,
    required this.section,
    required this.icon,
    required this.title,
    required this.value,
    required this.context,
    required this.statusLabel,
    required this.tone,
    required this.readiness,
    required this.action,
    required this.searchText,
    this.destructive = false,
  });

  final String id;
  final AccountSection section;
  final IconData icon;
  final String title;

  /// Görünen değer (e-posta, ad, rol, tarih…). Eksikse dürüst yer tutucu.
  final String value;

  /// Tek satır dürüst bağlam / kapsam notu.
  final String context;

  final String statusLabel;
  final AccountTone tone;
  final AccountReadiness readiness;
  final AccountAction action;
  final String searchText;
  final bool destructive;

  bool get isPartial => readiness != AccountReadiness.ready;
}

class AccountSummary {
  const AccountSummary({
    required this.profileReady,
    required this.contactReady,
    required this.requestReady,
    required this.messageReady,
    required this.savedFields,
  });

  final bool profileReady;
  final bool contactReady;
  final bool requestReady;
  final bool messageReady;

  /// Sunucuda gerçekten kayıtlı temel alan sayısı (e-posta + ad + telefon).
  final int savedFields;

  static const empty = AccountSummary(
    profileReady: false,
    contactReady: false,
    requestReady: true,
    messageReady: true,
    savedFields: 0,
  );
}

class AccountSnapshot {
  const AccountSnapshot({
    required this.entries,
    required this.summary,
    required this.signedIn,
    required this.greetingName,
    required this.email,
    required this.roleLabel,
    required this.avatarLetter,
    required this.coverageNote,
    required this.isEmpty,
  });

  final List<AccountEntry> entries;
  final AccountSummary summary;
  final bool signedIn;

  /// Gerçek ad (varsa); yoksa boş — uydurma isim yok.
  final String greetingName;
  final String email;
  final String roleLabel;
  final String avatarLetter;
  final String coverageNote;
  final bool isEmpty;

  /// Sekme/kısayol haritası — kanal aksiyonları için.
  static MainShellShortcut shortcutFor(AccountAction action) => switch (action) {
        AccountAction.goMessages => MainShellShortcut.openMessagesTab,
        AccountAction.goRequests => MainShellShortcut.openRequestsTab,
        AccountAction.goEngagement => MainShellShortcut.openFavoritesTab,
        _ => MainShellShortcut.openAccountTab,
      };
}
