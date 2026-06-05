import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';
import 'package:flutter/material.dart';

/// Saf/test edilebilir türetme. Tüm gösterim metni burada önceden hesaplanır;
/// build() içinde pahalı string/format işi yapılmaz. Girişler yalnızca primitif
/// (Firebase/Firestore tipleri sızmaz) — gerçek hesap alanları + dürüst
/// "Kayıtlı değil / Yakında" yer tutucuları.
AccountSnapshot computeAccountSnapshot({
  required bool signedIn,
  String? email,
  String? displayName,
  String? phone,
  String? memberSinceLabel,
  required bool emailVerified,
  String roleLabel = 'Müşteri',
  required String appVersion,
}) {
  final name = (displayName ?? '').trim();
  final mail = (email ?? '').trim();
  final phoneReal = (phone ?? '').trim();

  final avatarSource = mail.isNotEmpty ? mail : (name.isNotEmpty ? name : 'M');
  final avatarLetter =
      avatarSource.isNotEmpty ? avatarSource[0].toUpperCase() : '?';

  // Gerçekten kayıtlı temel alan sayısı (dürüst KPI).
  final savedFields = [
    mail.isNotEmpty,
    name.isNotEmpty,
    phoneReal.isNotEmpty,
  ].where((e) => e).length;

  final entries = <AccountEntry>[
    // ——— Hesap çekirdeği ———
    _entry(
      id: 'email',
      section: AccountSection.account,
      icon: Icons.alternate_email_rounded,
      title: 'E-posta',
      value: signedIn
          ? (mail.isNotEmpty ? mail : 'Kayıtlı değil')
          : 'Giriş yapılmamış',
      context: signedIn
          ? (emailVerified
              ? 'Hesap e-postası · doğrulanmış'
              : 'Hesap e-postası')
          : 'Giriş yaparak hesabınıza erişin',
      statusLabel: signedIn
          ? (mail.isNotEmpty ? 'Kayıtlı' : 'Eksik')
          : 'Giriş gerekli',
      tone: signedIn ? AccountTone.success : AccountTone.neutral,
      readiness:
          signedIn ? AccountReadiness.ready : AccountReadiness.blocked,
      action: AccountAction.detail,
    ),
    _entry(
      id: 'name',
      section: AccountSection.account,
      icon: Icons.badge_outlined,
      title: 'Görünen ad',
      value: name.isNotEmpty ? name : 'Kayıtlı değil',
      context: name.isNotEmpty
          ? 'Profil adınız'
          : 'Ad henüz kayıtlı değil · mesajdan paylaşabilirsiniz',
      statusLabel: name.isNotEmpty ? 'Kayıtlı' : 'Yakında',
      tone: name.isNotEmpty ? AccountTone.success : AccountTone.warning,
      readiness:
          name.isNotEmpty ? AccountReadiness.ready : AccountReadiness.partial,
      action: AccountAction.detail,
    ),
    _entry(
      id: 'role',
      section: AccountSection.account,
      icon: Icons.workspace_premium_outlined,
      title: 'Hesap türü',
      value: roleLabel,
      context: 'Müşteri portalı erişimi',
      statusLabel: 'Aktif',
      tone: AccountTone.accent,
      readiness: AccountReadiness.ready,
      action: AccountAction.detail,
    ),
    _entry(
      id: 'session',
      section: AccountSection.account,
      icon: Icons.verified_user_outlined,
      title: 'Oturum durumu',
      value: signedIn ? 'Aktif · güvenli bağlantı' : 'Oturum kapalı',
      context: signedIn
          ? 'Oturumunuz güvenli şekilde yönetilir'
          : 'Keşfet ve iletişim kanalları girişsiz de kullanılabilir',
      statusLabel: signedIn ? 'Aktif' : 'Kapalı',
      tone: signedIn ? AccountTone.success : AccountTone.neutral,
      readiness:
          signedIn ? AccountReadiness.ready : AccountReadiness.blocked,
      action: AccountAction.detail,
    ),
    if (signedIn)
      _entry(
        id: 'member_since',
        section: AccountSection.account,
        icon: Icons.event_outlined,
        title: 'Üyelik',
        value: (memberSinceLabel ?? '').trim().isNotEmpty
            ? 'Üye: ${memberSinceLabel!.trim()}'
            : 'Tarih kayıtlı değil',
        context: (memberSinceLabel ?? '').trim().isNotEmpty
            ? 'Hesap oluşturma tarihi'
            : 'Oluşturma tarihi sunucuda tutulmuyor',
        statusLabel: (memberSinceLabel ?? '').trim().isNotEmpty
            ? 'Kayıtlı'
            : 'Yok',
        tone: (memberSinceLabel ?? '').trim().isNotEmpty
            ? AccountTone.info
            : AccountTone.neutral,
        readiness: (memberSinceLabel ?? '').trim().isNotEmpty
            ? AccountReadiness.ready
            : AccountReadiness.partial,
        action: AccountAction.detail,
      ),

    // ——— İletişim ———
    _entry(
      id: 'phone',
      section: AccountSection.contact,
      icon: Icons.phone_outlined,
      title: 'Telefon',
      value: phoneReal.isNotEmpty ? phoneReal : 'Kayıtlı değil',
      context: phoneReal.isNotEmpty
          ? 'Kayıtlı iletişim numarası'
          : 'Telefon sunucuda tutulmuyor · mesajdan paylaşabilirsiniz',
      statusLabel: phoneReal.isNotEmpty ? 'Kayıtlı' : 'Yakında',
      tone: phoneReal.isNotEmpty ? AccountTone.success : AccountTone.warning,
      readiness:
          phoneReal.isNotEmpty ? AccountReadiness.ready : AccountReadiness.partial,
      action:
          phoneReal.isNotEmpty ? AccountAction.detail : AccountAction.goMessages,
    ),
    _entry(
      id: 'message_channel',
      section: AccountSection.contact,
      icon: Icons.forum_rounded,
      title: 'Mesaj kanalı',
      value: 'Danışmana doğrudan yazın',
      context: 'Mesaj kanalı hazır · gerçek iletişim',
      statusLabel: 'Hazır',
      tone: AccountTone.success,
      readiness: AccountReadiness.ready,
      action: AccountAction.goMessages,
    ),

    // ——— Hızlı geçiş ———
    _entry(
      id: 'requests',
      section: AccountSection.channels,
      icon: Icons.assignment_outlined,
      title: 'Talep merkezi',
      value: 'Talepler ve sonraki adımlar',
      context: 'Talep merkezi hazır · kayıt yakında',
      statusLabel: 'Hazır',
      tone: AccountTone.accent,
      readiness: AccountReadiness.ready,
      action: AccountAction.goRequests,
    ),
    _entry(
      id: 'engagement',
      section: AccountSection.channels,
      icon: Icons.favorite_rounded,
      title: 'İlgi & etkileşim',
      value: 'Favoriler ve etkileşim kanalları',
      context: 'İlgi yüzeyi hazır',
      statusLabel: 'Hazır',
      tone: AccountTone.info,
      readiness: AccountReadiness.ready,
      action: AccountAction.goEngagement,
    ),

    // ——— Gizlilik & destek ———
    _entry(
      id: 'privacy',
      section: AccountSection.privacy,
      icon: Icons.privacy_tip_outlined,
      title: 'KVKK & Gizlilik',
      value: 'Verileriniz nasıl kullanılır?',
      context: 'Bilgilendirme',
      statusLabel: 'Aç',
      tone: AccountTone.neutral,
      readiness: AccountReadiness.ready,
      action: AccountAction.privacy,
    ),
    _entry(
      id: 'support',
      section: AccountSection.privacy,
      icon: Icons.support_agent_rounded,
      title: 'Yardım & destek',
      value: 'İletişim kanallarına gidin',
      context: 'Mesaj kanalına yönlendirir',
      statusLabel: 'Hazır',
      tone: AccountTone.success,
      readiness: AccountReadiness.ready,
      action: AccountAction.goMessages,
    ),
    _entry(
      id: 'about',
      section: AccountSection.privacy,
      icon: Icons.info_outline_rounded,
      title: 'Uygulama bilgisi',
      value: 'Sürüm $appVersion',
      context: 'Bilgilendirme',
      statusLabel: 'Aç',
      tone: AccountTone.neutral,
      readiness: AccountReadiness.ready,
      action: AccountAction.about,
    ),

    // ——— Oturum ———
    if (signedIn)
      _entry(
        id: 'sign_out',
        section: AccountSection.session,
        icon: Icons.logout_rounded,
        title: 'Çıkış yap',
        value: 'Oturumu güvenle kapat',
        context: 'Hesabınızdan çıkış yapılır',
        statusLabel: 'Çıkış',
        tone: AccountTone.danger,
        readiness: AccountReadiness.ready,
        action: AccountAction.signOut,
        destructive: true,
      ),
  ];

  final summary = AccountSummary(
    profileReady: signedIn,
    contactReady: true,
    requestReady: true,
    messageReady: true,
    savedFields: savedFields,
  );

  return AccountSnapshot(
    entries: entries,
    summary: summary,
    signedIn: signedIn,
    greetingName: name,
    email: mail,
    roleLabel: roleLabel,
    avatarLetter: avatarLetter,
    coverageNote:
        'E-posta, hesap türü ve oturum gerçek hesabınızdan gelir. Telefon, '
        'profil düzenleme ve kayıtlı tercih geçmişi henüz sunucuda tutulmuyor; '
        'uydurma bilgi gösterilmez.',
    isEmpty: entries.isEmpty,
  );
}

AccountEntry _entry({
  required String id,
  required AccountSection section,
  required IconData icon,
  required String title,
  required String value,
  required String context,
  required String statusLabel,
  required AccountTone tone,
  required AccountReadiness readiness,
  required AccountAction action,
  bool destructive = false,
}) {
  final search = [title, value, context, statusLabel].join(' ').toLowerCase();
  return AccountEntry(
    id: id,
    section: section,
    icon: icon,
    title: title,
    value: value,
    context: context,
    statusLabel: statusLabel,
    tone: tone,
    readiness: readiness,
    action: action,
    searchText: search,
    destructive: destructive,
  );
}
