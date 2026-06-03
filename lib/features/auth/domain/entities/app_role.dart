/// Portivo CRM kullanıcı rolleri.
/// Yetki kontrolleri UI, veri ve security rules seviyesinde bu enum üzerinden yapılır.
/// (Enum zaten == ve hashCode sağlar; Equatable kullanılmaz)
enum AppRole {
  superAdmin('super_admin', 'Super Admin'),
  brokerOwner('broker_owner', 'Broker / Owner'),
  generalManager('general_manager', 'Genel Yönetici'),
  officeManager('office_manager', 'Ofis Müdürü'),
  teamLead('team_lead', 'Team Lead'),
  agent('agent', 'Danışman'),
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

  /// Firestore users.role değerinden AppRole.
  ///
  /// Güvenlik: kaldırılmış eski roller (operations, finance_investor,
  /// investor_portal, client) ve bilinmeyen değerler en düşük yetkili
  /// [AppRole.guest]'e düşürülür — eski bir kayıt asla yetki yükseltemez.
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
      // Kaldırılan eski roller → guest (yetki yükseltme imkânsız).
      case 'operations':
      case 'finance_investor':
      case 'financeinvestor':
      case 'investor_portal':
      case 'investor':
      case 'client':
      case 'müşteri':
        return AppRole.guest;
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

  /// Tüm çağrıları görebilme (Call Center, global call logs).
  /// İş gereği: sadece brokerOwner ve superAdmin seviyeleri.
  bool get canViewAllCalls => this == superAdmin || this == brokerOwner;

  /// Yatırımcı istihbarat paneli — yalnızca yönetici kademesi.
  bool get canViewInvestorIntelligence => isAdminTier;

  /// Danışman veya danışman-benzeri (agent, guest).
  bool get isConsultantTier => this == agent || this == guest;
}
