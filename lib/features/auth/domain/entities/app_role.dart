/// Rainbow CRM / EmlakMaster kullanıcı rolleri.
/// Yetki kontrolleri UI, veri ve security rules seviyesinde bu enum üzerinden yapılır.
/// (Enum zaten == ve hashCode sağlar; Equatable kullanılmaz)
enum AppRole {
  superAdmin('super_admin', 'Super Admin'),
  brokerOwner('broker_owner', 'Broker / Owner'),
  generalManager('general_manager', 'Genel Yönetici'),
  officeManager('office_manager', 'Ofis Müdürü'),
  teamLead('team_lead', 'Team Lead'),
  agent('agent', 'Danışman'),
  operations('operations', 'Operasyon Personeli'),
  financeInvestor('finance_investor', 'Finans / Yatırım'),
  investorPortal('investor_portal', 'Yatırımcı Portal'),
  client('client', 'Müşteri'),
  guest('guest', 'Demo Kullanıcı');

  const AppRole(this.id, this.label);
  final String id;
  final String label;

  static AppRole fromId(String? id) {
    if (id == null || id.isEmpty) return AppRole.guest;
    return AppRole.values.firstWhere(
      (r) => r.id == id,
      orElse: () => AppRole.guest,
    );
  }

  /// Firestore users.role değerinden AppRole. (broker→broker_owner, investor→investor_portal)
  static AppRole fromFirestoreRole(String? role) {
    if (role == null || role.isEmpty) return AppRole.guest;
    final n = role.trim().toLowerCase();
    switch (n) {
      case 'super_admin':
      case 'superadmin':
        return AppRole.superAdmin;
      case 'broker_owner':
      case 'broker':
        return AppRole.brokerOwner;
      case 'general_manager':
      case 'generalmanager':
        return AppRole.generalManager;
      case 'office_manager':
      case 'officemanager':
        return AppRole.officeManager;
      case 'team_lead':
      case 'teamlead':
        return AppRole.teamLead;
      case 'agent':
        return AppRole.agent;
      case 'operations':
        return AppRole.operations;
      case 'finance_investor':
      case 'financeinvestor':
        return AppRole.financeInvestor;
      case 'investor_portal':
      case 'investor':
        return AppRole.investorPortal;
      case 'client':
      case 'müşteri':
        return AppRole.client;
      default:
        return AppRole.values.firstWhere(
          (r) => r.id == n || r.id.replaceAll('_', '') == n.replaceAll('_', ''),
          orElse: () => AppRole.guest,
        );
    }
  }

  bool get isAdminTier =>
      this == superAdmin || this == brokerOwner || this == generalManager;
  bool get isManagerTier =>
      isAdminTier || this == officeManager || this == teamLead;
  bool get canViewAllCalls => isManagerTier || this == operations;
  bool get canViewInvestorIntelligence =>
      isAdminTier || this == financeInvestor || this == investorPortal;

  /// Müşteri portalı: arama, favoriler, mesajlar, sanal tur.
  bool get isClientTier => this == AppRole.client;

  /// Danışman veya danışman-benzeri (agent, guest, investor vb.).
  bool get isConsultantTier =>
      this == agent ||
      this == guest ||
      this == financeInvestor ||
      this == investorPortal;
}
