import 'entities/app_role.dart';

/// Self-service kayıtta manuel **seçilebilir** roller (ofis-öncesi başlangıç rolü).
///
/// GÜVENLİK: Yönetici/admin kademesi (broker_owner, general_manager,
/// office_manager, team_lead) self-service ile ATANAMAZ. Yönetici olmak için:
/// - kendi ofisini OLUŞTUR (→ broker_owner), ya da
/// - bir ofis DAVETİNİ kabul et (→ manager/admin/consultant).
/// Bu akışlar yetkiyi sunucu tarafında doğrular.
///
/// `super_admin` HİÇBİR KOŞULDA kayıt akışından atanamaz — platform sahibi
/// hesabı yalnızca sunucu tarafında (Firestore) tanımlıdır.
List<AppRole> selfServiceSelectableRoles() => const [AppRole.agent];

/// İlk giriş / giriş ekranında kullanıcının seçtiği operasyon yolu.
enum LoginEntryPersona {
  manager,
  consultant;

  String get id => name;

  static LoginEntryPersona? fromId(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final p in LoginEntryPersona.values) {
      if (p.id == raw) return p;
    }
    return null;
  }

  static LoginEntryPersona fromRole(AppRole role) {
    if (_managerRoles.contains(role)) return LoginEntryPersona.manager;
    return LoginEntryPersona.consultant;
  }

  static const _managerRoles = <AppRole>{
    AppRole.superAdmin,
    AppRole.brokerOwner,
    AppRole.generalManager,
    AppRole.officeManager,
    AppRole.teamLead,
  };

  bool matchesRole(AppRole role) {
    switch (this) {
      case LoginEntryPersona.manager:
        return _managerRoles.contains(role);
      case LoginEntryPersona.consultant:
        return !_managerRoles.contains(role);
    }
  }

  List<AppRole> filterSelectableRoles(List<AppRole> all) {
    final filtered = all.where((r) {
      // super_admin seçim listelerinde asla görünmez.
      if (r == AppRole.superAdmin) return false;
      return matchesRole(r);
    }).toList();
    if (filtered.isNotEmpty) return filtered;
    return all;
  }

  /// Yerelleştirme anahtarları (AppLocalizations.t ile çözülür).
  String get loginTitleKey {
    switch (this) {
      case LoginEntryPersona.manager:
        return 'persona_manager_login_title';
      case LoginEntryPersona.consultant:
        return 'persona_consultant_login_title';
    }
  }

  String get loginSubtitleKey {
    switch (this) {
      case LoginEntryPersona.manager:
        return 'persona_manager_login_subtitle';
      case LoginEntryPersona.consultant:
        return 'persona_consultant_login_subtitle';
    }
  }

  String get rolePathTitleKey {
    switch (this) {
      case LoginEntryPersona.manager:
        return 'persona_manager_role_title';
      case LoginEntryPersona.consultant:
        return 'persona_consultant_role_title';
    }
  }

  String get rolePathSubtitleKey {
    switch (this) {
      case LoginEntryPersona.manager:
        return 'persona_manager_role_subtitle';
      case LoginEntryPersona.consultant:
        return 'persona_consultant_role_subtitle';
    }
  }
}
