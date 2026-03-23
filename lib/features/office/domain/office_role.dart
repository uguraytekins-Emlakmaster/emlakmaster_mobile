import '../../auth/domain/entities/app_role.dart';

/// Ofis içi rol — [AppRole] ile eşlenir; yetki kaynağı üyeliktir.
enum OfficeRole {
  owner,
  admin,
  manager,
  consultant,
}

extension OfficeRoleFirestore on OfficeRole {
  String get firestoreValue {
    switch (this) {
      case OfficeRole.owner:
        return 'owner';
      case OfficeRole.admin:
        return 'admin';
      case OfficeRole.manager:
        return 'manager';
      case OfficeRole.consultant:
        return 'consultant';
    }
  }

  /// [RolePermissionRegistry] ile uyum için [AppRole] eşlemesi.
  AppRole toAppRole() {
    switch (this) {
      case OfficeRole.owner:
        return AppRole.brokerOwner;
      case OfficeRole.admin:
        return AppRole.officeManager;
      case OfficeRole.manager:
        return AppRole.teamLead;
      case OfficeRole.consultant:
        return AppRole.agent;
    }
  }
}

OfficeRole? parseOfficeRole(String? v) {
  if (v == null || v.isEmpty) return null;
  switch (v.trim().toLowerCase()) {
    case 'owner':
      return OfficeRole.owner;
    case 'admin':
      return OfficeRole.admin;
    case 'manager':
      return OfficeRole.manager;
    case 'consultant':
      return OfficeRole.consultant;
    default:
      return null;
  }
}
