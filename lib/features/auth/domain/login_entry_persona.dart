import 'entities/app_role.dart';

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

  List<AppRole> filterSelectableRoles(
    List<AppRole> all, {
    required bool includeSuperAdmin,
  }) {
    final filtered = all.where((r) {
      if (r == AppRole.superAdmin && !includeSuperAdmin) return false;
      return matchesRole(r);
    }).toList();
    if (filtered.isNotEmpty) return filtered;
    return all;
  }

  String get loginTitle {
    switch (this) {
      case LoginEntryPersona.manager:
        return 'Yönetici girişi';
      case LoginEntryPersona.consultant:
        return 'Danışman girişi';
    }
  }

  String get loginSubtitle {
    switch (this) {
      case LoginEntryPersona.manager:
        return 'Komuta masası, ekip ve çağrı merkezi tek akışta';
      case LoginEntryPersona.consultant:
        return 'Müşteri, ilan ve görüşme operasyonunuz tek yerde';
    }
  }

  String get rolePathTitle {
    switch (this) {
      case LoginEntryPersona.manager:
        return 'Yönetici olarak devam';
      case LoginEntryPersona.consultant:
        return 'Danışman olarak devam';
    }
  }

  String get rolePathSubtitle {
    switch (this) {
      case LoginEntryPersona.manager:
        return 'Ofis, ekip liderliği ve operasyon yetkileri';
      case LoginEntryPersona.consultant:
        return 'Saha danışmanı ve portföy odaklı panel';
    }
  }
}
