/// Yapılandırılmış izin anahtarları — Firestore rules / UI / adapter ile hizalanmalı.
/// Rol eşlemesi: [RolePermissionRegistry].
enum PermissionId {
  manageOfficeSettings,
  manageMembers,
  manageInvites,
  manageOwnListings,
  manageTeamListings,
  manageOwnIntegrations,
  manageOfficeIntegrations,
  viewMessages,
  replyMessages,
  runManualSync,
  viewAdminDiagnostics,
  viewAuditLog,
  approveImports,
}
