enum MembershipStatus {
  /// Normal çalışma
  active,
  /// Davet kabul edilmedi / tamamlanmadı — tam uygulama erişimi yok
  invited,
  /// Geçici blok
  suspended,
  /// Üyelik sonlandı
  removed,
}

extension MembershipStatusX on MembershipStatus {
  bool get allowsFullOfficeAccess => this == MembershipStatus.active;
}

MembershipStatus? parseMembershipStatus(String? v) {
  if (v == null || v.isEmpty) return null;
  switch (v.trim().toLowerCase()) {
    case 'active':
      return MembershipStatus.active;
    case 'invited':
      return MembershipStatus.invited;
    case 'suspended':
      return MembershipStatus.suspended;
    case 'removed':
      return MembershipStatus.removed;
    default:
      return null;
  }
}
