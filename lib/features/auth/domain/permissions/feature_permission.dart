import '../entities/app_role.dart';

/// Rol bazlı özellik yetkileri. UI ve veri katmanında kullanılır.
abstract final class FeaturePermission {
  /// Executive dashboard: tüm KPI ve paneller
  static bool canViewFullDashboard(AppRole role) =>
      role.isAdminTier || role == AppRole.officeManager || role == AppRole.teamLead;

  /// Sadece kendi metrikleri
  static bool canViewOwnDashboard(AppRole role) => true;

  /// Manager Command Center / Call Center
  static bool canViewCallCenter(AppRole role) =>
      role.canViewAllCalls || role == AppRole.agent;

  static bool canViewAllCalls(AppRole role) => role.canViewAllCalls;

  /// Müşteri: tüm müşterileri görme
  static bool canViewAllCustomers(AppRole role) =>
      role.isManagerTier || role == AppRole.operations || role == AppRole.agent;

  /// Sadece atanmış müşteriler
  static bool canViewAssignedCustomersOnly(AppRole role) =>
      role == AppRole.agent;

  /// İlan yönetimi
  static bool canManageListings(AppRole role) =>
      role.isManagerTier || role == AppRole.agent || role == AppRole.operations;

  /// Pipeline / satış hunisi
  static bool canViewPipeline(AppRole role) =>
      role != AppRole.guest && role != AppRole.investorPortal;

  static bool canEditPipeline(AppRole role) =>
      role.isManagerTier || role == AppRole.agent;

  /// Raporlar
  static bool canViewReports(AppRole role) =>
      role.isManagerTier || role == AppRole.financeInvestor;

  /// Yatırımcı istihbarat paneli
  static bool canViewInvestorIntelligence(AppRole role) =>
      role.canViewInvestorIntelligence;

  /// Ayarlar / rol yönetimi
  static bool canManageSettings(AppRole role) =>
      role == AppRole.superAdmin || role == AppRole.brokerOwner;

  /// Audit log
  static bool canViewAuditLog(AppRole role) =>
      role == AppRole.superAdmin || role == AppRole.brokerOwner || role == AppRole.generalManager;

  /// Sistem sağlığı
  static bool canViewSystemHealth(AppRole role) =>
      role == AppRole.superAdmin || role == AppRole.brokerOwner;

  /// War Room / Manager Focus (yönetici günlük odak paneli)
  static bool canViewWarRoom(AppRole role) =>
      role.isManagerTier || role == AppRole.operations;

  /// Resurrection queue (sessiz lead listesi)
  static bool canViewResurrectionQueue(AppRole role) =>
      role.isManagerTier || role == AppRole.agent || role == AppRole.operations;

  /// Opportunity Radar / Voice of Market
  static bool canViewOpportunityRadar(AppRole role) =>
      role.isManagerTier || role == AppRole.operations;

  /// Yönetici paneli: tam dashboard, War Room, çağrı merkezi, raporlar, sistem.
  static bool seesAdminPanel(AppRole role) =>
      role.isManagerTier || role == AppRole.operations;

  /// Danışman paneli: kendi özeti, müşteriler, ilanlar, Magic Call, resurrection.
  static bool seesConsultantPanel(AppRole role) =>
      role == AppRole.agent ||
      role == AppRole.guest ||
      role == AppRole.financeInvestor ||
      role == AppRole.investorPortal;
}
