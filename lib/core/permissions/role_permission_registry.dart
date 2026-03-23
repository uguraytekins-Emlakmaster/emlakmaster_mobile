import '../../features/auth/domain/entities/app_role.dart';

import 'permission_id.dart';

/// Rol → izin kümesi. [FeaturePermission] ile birlikte kullanılır; yeni ekranlar buradan okuyabilir.
abstract final class RolePermissionRegistry {
  static Set<PermissionId> forRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.brokerOwner:
        return PermissionId.values.toSet();
      case AppRole.generalManager:
        return {
          PermissionId.manageOfficeSettings,
          PermissionId.manageMembers,
          PermissionId.manageInvites,
          PermissionId.manageTeamListings,
          PermissionId.manageOfficeIntegrations,
          PermissionId.viewMessages,
          PermissionId.replyMessages,
          PermissionId.runManualSync,
          PermissionId.viewAdminDiagnostics,
          PermissionId.viewAuditLog,
          PermissionId.approveImports,
          PermissionId.manageOwnListings,
          PermissionId.manageOwnIntegrations,
        };
      case AppRole.officeManager:
      case AppRole.teamLead:
        return {
          PermissionId.manageMembers,
          PermissionId.manageInvites,
          PermissionId.manageTeamListings,
          PermissionId.manageOfficeIntegrations,
          PermissionId.viewMessages,
          PermissionId.replyMessages,
          PermissionId.runManualSync,
          PermissionId.manageOwnListings,
          PermissionId.manageOwnIntegrations,
        };
      case AppRole.agent:
      case AppRole.operations:
        return {
          PermissionId.manageOwnListings,
          PermissionId.manageOwnIntegrations,
          PermissionId.viewMessages,
          PermissionId.runManualSync,
        };
      case AppRole.financeInvestor:
        return {
          PermissionId.viewAdminDiagnostics,
          PermissionId.manageOwnListings,
        };
      case AppRole.investorPortal:
      case AppRole.client:
        return {
          PermissionId.viewMessages,
        };
      case AppRole.guest:
        return {};
    }
  }

  static bool has(AppRole role, PermissionId p) => forRole(role).contains(p);
}
